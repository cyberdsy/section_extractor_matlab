function varargout = SectionExtractor(varargin)
% SECTIONEXTRACTOR MATLAB code for SectionExtractor.fig
%      SECTIONEXTRACTOR, by itself, creates a new SECTIONEXTRACTOR or raises the existing
%      singleton*.
%
%      H = SECTIONEXTRACTOR returns the handle to a new SECTIONEXTRACTOR or the handle to
%      the existing singleton*.
%
%      SECTIONEXTRACTOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SECTIONEXTRACTOR.M with the given input arguments.
%
%      SECTIONEXTRACTOR('Property','Value',...) creates a new SECTIONEXTRACTOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SectionExtractor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SectionExtractor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SectionExtractor

% Last Modified by GUIDE v2.5 05-Jul-2012 16:08:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SectionExtractor_OpeningFcn, ...
                   'gui_OutputFcn',  @SectionExtractor_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SectionExtractor is made visible.
function SectionExtractor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SectionExtractor (see VARARGIN)

set(handles.axes1,'Visible','off');
set(handles.listbox_ROIs,'Visible','off');
userData.dilateim = 'true';
userData.closeim = 'true';
userData.erodeim = 'true';
userData.ImageMode = 'fluoro';
userData.OutputMode = 'Single';
userData.Segmentation.choice = 'all';

% Choose default command line output for SectionExtractor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
set(handles.figure1,'UserData',userData);
% UIWAIT makes SectionExtractor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SectionExtractor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_Segment.
function pushbutton_Segment_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Segment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1,'UserData');
 
if ~isfield(userData,'slideFile')
    errordlg('Load a slide image first','modal')
    return
elseif ~isfield(userData,'thumbNailFile')
    errordlg('Load a thumbnail image first','modal')
    return    
else
    numChan = userData.inChannels;
    choice = userData.Segmentation.choice;
    ROIvec = userData.ROIslide;
    
    switch choice
        case 'all'
            first = 1;
            last = size(ROIvec,1);
            contents = first:last;
        case 'selected'
            contents = get(handles.listbox_ROIs,'Value');
            first = 1;
            last = length(contents);
    end
    
    mode = userData.OutputMode;

    switch mode
        case 'RGB'
                outChan = 1:3;
                inChan = 1:numChan;
        case 'Single'
                outChan = str2double(get(handles.edit_outchan,'String'));  
                if outChan > numChan
                    errordlg('The channel does not exist in the input image','modal')
                    return
                else
                    inChan = outChan;
                end
    end

    
    popupselec = get(handles.popupmenu_scale,'Value');
    popupcontents = cellstr(get(handles.popupmenu_scale,'String'));
    scalefact = str2num(popupcontents{popupselec});
    if scalefact
        reslevel = log2(scalefact);
    end
    blocksize = [2000 2000];

    slideFile = userData.slideFile;
    fname_length = length(slideFile);
    slideFilename = slideFile(1:fname_length - 4);
    
    my_adapter = ImarisROIAdapter(slideFile,'r',reslevel,inChan);

    tic

    %Loop over identified tissue sections. This part can be modified. Set the
    %index iImage to 1 to segment a single section. Set it to any integer value
    %between 1 and the length of idx to select a single section from the list
    %of coordinates in bounding box. Or set values of ROI if these are known
    %and make iImage = 1 (ROI = [x y width height].
    for ii = first: last
        iSection = contents(ii);  
        % Crop a portion of the image set by the bounding box
        ROI = ROIvec(iSection,:);
        outImageSize = [floor(ROI(3)) floor(ROI(4)) length(outChan)];
        
        % make filename for each tissue section
        if iSection < 10
            tiss_seq_tif = sprintf([slideFilename,'section_00%d.tif'],iSection);
        elseif iSection >= 10 && iSection < 100
            tiss_seq_tif = sprintf([slideFilename,'section_0%d.tif'],iSection);
        elseif iSection >= 100
            tiss_seq_tif = sprintf([slideFilename,'section_%d.tif'],iSection);
        end
        
        if outImageSize(1) > blocksize(1) || outImageSize(2) > blocksize(2)
            %display tissue section name and ROI vector to command line
            tiss_seq_tif
            ROI
            
            %set up the output image size and cropping function
            imgCropFcn = @(block_struct) LargeImageCropFcn(block_struct.data,block_struct.location,blocksize,ROI);

            FillVal = 1;
            FillVal = uint8(FillVal);

            %do the cropping and saving of new images
            my_output_adapter = ImarisROIAdapter(tiss_seq_tif,'w',reslevel,outChan,outImageSize,FillVal);
            blockprocROI(my_adapter,blocksize,imgCropFcn,'UseParallel',true,'Destination',my_output_adapter);
            my_output_adapter.close
            clear my_output_adapter;
        else
            %display tissue section name and ROI vector to command line
            tiss_seq_tif
            ROI
            
            pixRegion(1) = ROI(1);
            pixRegion(2) = ROI(3);
            pixRegion(3) = ROI(2);
            pixRegion(4) = ROI(4);
            
            img = imreadImaris(slideFile,outImageSize,reslevel,1,1,inChan,pixRegion);
            % if the output image is RGB but the input number of channels
            % is 2
            if length(outChan) == 3
                if length(outChan) > numChan
                    img(:,:,3) = uint8(zeros(outImageSize(1),outImageSize(2)));
                end
                img_new(:,:,1) = img(:,:,3);
                img_new(:,:,2) = img(:,:,2);
                img_new(:,:,3) = img(:,:,1);
                img = img_new;
            end
            imwrite(uint8(img),tiss_seq_tif,'compression','lzw');

        end
    end
    toc
end

% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcbf)


function edit_thumbnail_Callback(hObject, eventdata, handles)
% hObject    handle to edit_thumbnail (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_thumbnail as text
%        str2double(get(hObject,'String')) returns contents of edit_thumbnail as a double


% --- Executes during object creation, after setting all properties.
function edit_thumbnail_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_thumbnail (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in listbox_slides.
function listbox_slides_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_slides (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_slides contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_slides


% --- Executes during object creation, after setting all properties.
function listbox_slides_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_slides (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_up.
function pushbutton_up_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_removeSlide.
function pushbutton_removeSlide_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_removeSlide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_addSlide.
function pushbutton_addSlide_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_addSlide (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1, 'UserData');

%open a calibration file
[fname,path] = uigetfile('*.ims');
cd(path);

set(handles.edit_slideFile,'String',fname,'Value',1);

userData.slideFile = fname;
meta = imreadImarismeta(fname,0);
slideSize(1,1) = meta.height;
slideSize(1,2) = meta.width;
thumbmeta = imreadImarismeta(fname,4);
thumbSize(1,1) = thumbmeta.height;
thumbSize(1,2) = thumbmeta.width;
numchan = meta.channels;
channel = str2double(get(handles.edit_channel,'String'));
thumb = imreadImaris(fname,thumbSize,4,1,1,channel);
set(handles.figure1,'CurrentAxes',handles.axes1)
imagesc(thumb),colormap 'gray',axis off

userData.thumbNailFile = fname;
userData.thumbNailIm = thumb;

userData.slideSize = slideSize;
userData.inChannels = numchan;
set(handles.figure1, 'UserData', userData);


% --- Executes on button press in pushbutton_down.
function pushbutton_down_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_down (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox_dilate.
function checkbox_dilate_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_dilate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.figure1,'UserData');

% Hint: get(hObject,'Value') returns toggle state of checkbox_dilate
if (get(hObject,'Value') == get(hObject,'Max'))
    userData.dilateim = 'true';
else
    userData.dilateim = 'false';
end
set(handles.figure1,'UserData',userData);

% --- Executes on button press in checkbox_close.
function checkbox_close_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.figure1,'UserData');

% Hint: get(hObject,'Value') returns toggle state of checkbox_dilate
if (get(hObject,'Value') == get(hObject,'Max'))
    userData.closeim = 'true';
else
    userData.closeim = 'false';
end
set(handles.figure1,'UserData',userData);



function edit_threshlo_Callback(hObject, eventdata, handles)
% hObject    handle to edit_threshlo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_threshlo as text
%        str2double(get(hObject,'String')) returns contents of edit_threshlo as a double


% --- Executes during object creation, after setting all properties.
function edit_threshlo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_threshlo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_setThresh.
function pushbutton_setThresh_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_setThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1,'UserData');
channel = str2double(get(handles.edit_channel,'String'));
if channel > 0
    thumb = userData.thumbNailIm;

    %Identify tissue section
%     [minlevel,minlevelper,maxlevel,maxlevelper,bw] ...
%         = thresh_tool_dan_percent(thumb(:,:,channel));
    [minlevel,bw] ...
        = thresh_tool(thumb(:,:,channel));

    thresh = minlevel;
    set(handles.edit_threshlo,'String',num2str(round(thresh)));

    userData.threshold = thresh;
    set(handles.figure1,'UserData',userData);
else
    errordlg('Channel should be 1, 2 or 3','modal')
    return
end

% --- Executes on button press in checkbox_erode.
function checkbox_erode_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_erode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.figure1,'UserData');

% Hint: get(hObject,'Value') returns toggle state of checkbox_dilate
if (get(hObject,'Value') == get(hObject,'Max'))
    userData.erodeim = 'true';
else
    userData.erodeim = 'false';
end
set(handles.figure1,'UserData',userData);




function edit_dilateSE_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dilateSE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dilateSE as text
%        str2double(get(hObject,'String')) returns contents of edit_dilateSE as a double


% --- Executes during object creation, after setting all properties.
function edit_dilateSE_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dilateSE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_erodeSE_Callback(hObject, eventdata, handles)
% hObject    handle to edit_erodeSE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_erodeSE as text
%        str2double(get(hObject,'String')) returns contents of edit_erodeSE as a double


% --- Executes during object creation, after setting all properties.
function edit_erodeSE_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_erodeSE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_processThumb.
function pushbutton_processThumb_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_processThumb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.figure1,'UserData');
 
if ~isfield(userData,'slideFile')
    errordlg('Load a slide image first','modal')
    return
elseif ~isfield(userData,'thumbNailFile')
    errordlg('Load a thumbnail image first','modal')
    return    
else
    set(handles.figure1,'CurrentAxes',handles.axes1);
    
    channel = str2double(get(handles.edit_channel,'String'));
    
    if channel > 0
        
        fname = userData.slideFile;
        threshlo = str2double(get(handles.edit_threshlo,'String'));
        popupselec = get(handles.popupmenu_scale,'Value');
        popupcontents = cellstr(get(handles.popupmenu_scale,'String'));

        meta = imreadImarismeta(fname,0);
        slideSize(1,1) = meta.height;
        slideSize(1,2) = meta.width;

        thumb = userData.thumbNailIm;
        dilateim = userData.dilateim;
        closeim = userData.closeim;
        erodeim = userData.erodeim;
        thumbSize = size(thumb);
        thumbSize = thumbSize(1,1:2);
        
        scale = double(thumbSize) ./ double(slideSize);
        mode = userData.ImageMode;

        switch mode
            case 'bright'
                BW = thumb(:,:,channel) < threshlo;
            case 'fluoro'
                BW = thumb(:,:,channel) > threshlo;
        end

        imagesc(BW);colormap 'gray';axis off;

        if dilateim
            dilSize = str2double(get(handles.edit_dilateSE,'String'));
            se = strel('disk',dilSize);
            BWdil = imdilate(BW,se);
            imagesc(BWdil);colormap 'gray';axis off;
        else
            BWdil = BW;
        end

        if closeim
            BWclose = imfill(BWdil,'holes');
            imagesc(BWclose), colormap 'gray';axis off;
        else
            BWclose = BWdil;
        end

        if erodeim
            eroSize = str2double(get(handles.edit_erodeSE,'String'));
            se = strel('disk',eroSize);
            BWero = imerode(BWclose,se);
            imagesc(BWero);colormap 'gray';axis off;
        else
            BWero = BWclose;
        end

        % find the connected components
        cc = bwconncomp(BWero);
        L = labelmatrix(cc);

        %filter by area to remove small objects
        stats = regionprops(L,'Area');
        idx = find([stats.Area]>400);
        BWopen = ismember(L,idx);

        % create new connected components list for filtered objects
        cc2keep = bwconncomp(BWopen);
        L2keep = labelmatrix(cc2keep);
        s = regionprops(cc2keep, 'PixelIdxList', 'Centroid','BoundingBox');
        section_map = ind2rgb(L2keep,jet(10));
        imagesc(section_map);colormap 'gray';axis off;


        %label the objects
        hold on
        for k = 1:numel(s)
            x = s(k).Centroid(1);
            y = s(k).Centroid(2);
            text(x, y, sprintf('%d',k), 'Color', 'r', ...
                'FontWeight', 'bold');
            ROI(k,:) = (s(k).BoundingBox);
            ROIslide (k,1) = floor(ROI(k,2) ./ scale(1));
            ROIslide (k,2) = floor(ROI(k,1) ./ scale(1));
            ROIslide (k,3) = floor(ROI(k,4) ./ scale(2));
            ROIslide (k,4) = floor(ROI(k,3) ./ scale(2));
        end
        x = ROI(1,1);
        y = ROI(1,2);
        w = ROI(1,3);
        h = ROI(1,4);
        rectangle('Position',[x,y,w,h],'EdgeColor','r')
        hold off

        userData.Sections = s;
        userData.ROI = ROIslide;
        userData.section_map = section_map;
        userData.slideSize = slideSize;
        set(handles.figure1,'UserData',userData);        
        set(handles.text_numROIs,'String',strcat('Number of sections = ',num2str(numel(s))));
        set(handles.text_numROIs,'Visible','on');
        set(handles.listbox_ROIs,'Visible','on');
        set(handles.listbox_ROIs,'String',num2str(ROIslide),'Value',1);
        set(handles.popupmenu_scale,'String',{'1','2','4','8','16','32','64'},'Value',1);
    else
        errordlg('Channel should be 1, 2 or 3','modal')
        return
        
    end

end

% --- Executes on button press in pushbutton_clearROIs.
function pushbutton_clearROIs_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clearROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1,'UserData');

if ~isfield(userData,'thumbNailFile')
    errordlg('Load a thumbnail image first','modal')
    return
else
    set(handles.figure1,'CurrentAxes',handles.axes1);
    thumb = userData.thumbNailIm;
    imagesc(thumb),colormap 'gray',axis off
    set(handles.listbox_ROIs,'Visible','off');
    set(handles.text_numROIs,'Visible','off');
end


% --- Executes on selection change in listbox_ROIs.
function listbox_ROIs_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_ROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_ROIs contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_ROIs
userData = get(handles.figure1,'UserData');
if ~isfield(userData,'thumbNailFile')
    errordlg('Load a thumbnail image first','modal')
    return
else
    contents = cellstr(get(hObject,'String'));
    pos = get(hObject,'Value');
    ROIvec = contents{get(hObject,'Value')};
    
    section_map = userData.section_map;
    s = userData.Sections;
    imagesc(section_map);colormap 'gray';axis off;


    %label the objects
    hold on
    for k = 1:numel(s)
        x = s(k).Centroid(1);
        y = s(k).Centroid(2);
        text(x, y, sprintf('%d',k), 'Color', 'r', ...
            'FontWeight', 'bold');
        ROI(k,:) = (s(k).BoundingBox);
    end
    
    for kk = 1:length(pos)
        x(kk) = ROI(pos(kk),1);
        y(kk) = ROI(pos(kk),2);
        w(kk) = ROI(pos(kk),3);
        h(kk) = ROI(pos(kk),4);
        rectangle('Position',[x(kk),y(kk),w(kk),h(kk)],'EdgeColor','r');
    end
    hold off
end


% --- Executes during object creation, after setting all properties.
function listbox_ROIs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_ROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uipanel4.
function uipanel4_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel4 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1, 'UserData');
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton_bright'
        userData.ImageMode = 'bright';
    case 'radiobutton1_fluoro'
        userData.ImageMode = 'fluoro';
end
set(handles.figure1, 'UserData', userData);


% --- Executes when selected object is changed in uipanel5.
function uipanel5_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel5 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1, 'UserData');
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton_allSec'
        userData.Segmentation.choice = 'all';
    case 'radiobutton_selSec'
        userData.Segmentation.choice = 'selected';
end
set(handles.figure1, 'UserData', userData);



function edit_slideFile_Callback(hObject, eventdata, handles)
% hObject    handle to edit_slideFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_slideFile as text
%        str2double(get(hObject,'String')) returns contents of edit_slideFile as a double


% --- Executes during object creation, after setting all properties.
function edit_slideFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_slideFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_channel_Callback(hObject, eventdata, handles)
% hObject    handle to edit_channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_channel as text
%        str2double(get(hObject,'String')) returns contents of edit_channel as a double


% --- Executes during object creation, after setting all properties.
function edit_channel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_threshhi_Callback(hObject, eventdata, handles)
% hObject    handle to edit_threshhi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_threshhi as text
%        str2double(get(hObject,'String')) returns contents of edit_threshhi as a double


% --- Executes during object creation, after setting all properties.
function edit_threshhi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_threshhi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_scale.
function popupmenu_scale_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_scale contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_scale
userData = get(handles.figure1,'UserData');
ROI = userData.ROI;
fname = userData.slideFile;
slideSize = userData.slideSize;
popupselec = get(handles.popupmenu_scale,'Value');
popupcontents = cellstr(get(handles.popupmenu_scale,'String'));
scalefact = str2num(popupcontents{popupselec});
if isempty(scalefact)
    reslevel = 1;
else
    reslevel = log2(scalefact);
end
meta = imreadImarismeta(fname,reslevel);
thumbSize(1,1) = meta.height;
thumbSize(1,2) = meta.width;

scale = double(thumbSize) ./ double(slideSize);

for k = 1:length(ROI)
    ROIslide(k,1) = floor(ROI(k,1) .* scale(1));
    ROIslide(k,2) = floor(ROI(k,2) .* scale(1));
    ROIslide(k,3) = floor(ROI(k,3) .* scale(2));
    ROIslide(k,4) = floor(ROI(k,4) .* scale(2));
end

set(handles.listbox_ROIs,'Visible','on');
set(handles.listbox_ROIs,'String',num2str(ROIslide),'Value',1);
userData.ROIslide = ROIslide;
set(handles.figure1,'UserData',userData);


% --- Executes during object creation, after setting all properties.
function popupmenu_scale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_outchan_Callback(hObject, eventdata, handles)
% hObject    handle to edit_outchan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_outchan as text
%        str2double(get(hObject,'String')) returns contents of edit_outchan as a double


% --- Executes during object creation, after setting all properties.
function edit_outchan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_outchan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uipanel_imout.
function uipanel_imout_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_imout 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1, 'UserData');
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radiobutton_RGB'
        userData.OutputMode = 'RGB';
    case 'radiobutton_single'
        userData.OutputMode = 'Single';
end
set(handles.figure1, 'UserData', userData);
