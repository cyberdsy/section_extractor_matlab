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

% Last Modified by GUIDE v2.5 16-Jul-2012 10:17:32

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
set(handles.listbox_ROIs,'Visible','on');
set(handles.uipanel_info,'Visible','off');
userData.dilateim = 'true';
userData.closeim = 'true';
userData.erodeim = 'true';
userData.ImageMode = 'fluoro';
userData.OutputMode = 'Single';
userData.Segmentation.choice = 'all';
userData.ROI.roicounter = 0;
userData.imseg = 'auto';

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
    errordlg('Load a slide image first','ERROR')
    return
elseif ~isfield(userData,'thumbNailFile')
    errordlg('Load a thumbnail image first','ERROR')
    return    
else
    numChan = userData.inChannels;
    choice = userData.Segmentation.choice;
    
    if ~isfield(userData.ROI,'scaled')
        imseg = userData.imseg;
        switch imseg
            case 'auto'
                ROIvec = userData.ROI.autoloc;
            case'man'
                ROIvec = userData.ROI.manualloc;
        end
    else
        ROIvec = userData.ROI.scaled;
    end
    
    mode = userData.OutputMode;
    
    switch choice
        case 'all'
            contents = 1:size(ROIvec,1);
        case 'selected'
            listcontents = get(handles.listbox_ROIs,'Value');
            contents = 1:length(listcontents);
    end

    switch mode
        case 'RGB'
                outChan = 1:3;
                inChan = 1:numChan;
        case 'Single'
                outChan = str2double(get(handles.edit_outchan,'String'));  
                if outChan > numChan
                    errordlg('The channel does not exist in the input image','ERROR')
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
    else
        reslevel = 0;
    end

    slideFile = userData.slideFile;
    
    sectionImWrite(slideFile,ROIvec,numChan,inChan,outChan,contents,reslevel)
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

[fname,path] = uigetfile('*.ims');
cd(path);

set(handles.edit_slideFile,'String',fname,'Value',1);
set(handles.uipanel_info,'Visible','on');
userData.slideFile = fname;
meta = imreadImarismeta(fname,0);
slideSize(1,1) = meta.height;
slideSize(1,2) = meta.width;
thumbmeta = imreadImarismeta(fname,5);
thumbSize(1,1) = thumbmeta.height;
thumbSize(1,2) = thumbmeta.width;
numchan = meta.channels;
channel = str2double(get(handles.edit_channel,'String'));

set(handles.text_width,'String',['Image width =  ',num2str(slideSize(1,2))]);
set(handles.text_height,'String',['Image height =  ',num2str(slideSize(1,1))]);
set(handles.text_channels,'String',['Number of channels =  ',num2str(numchan)]);

thumb = imreadImaris(fname,thumbSize,5,1,1,channel);
set(handles.figure1,'CurrentAxes',handles.axes1);
imagesc(thumb);colormap gray;axis off;
userData.thumbNailFile = fname;
userData.thumbNailIm = thumb;
userData.thumbSize = thumbSize;
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
userData = get(handles.figure1, 'UserData');

if ~isfield(userData,'slideFile')
    errordlg('Load an image first','ERROR')
    set(handles.edit_threshlo,'String','0');
    return
end

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
if ~isfield(userData,'thumbNailFile')
    errordlg('Load an image first','ERROR')
    return
else
    thumb = userData.thumbNailIm;

    %Identify tissue section
%     [minlevel,minlevelper,maxlevel,maxlevelper,bw] ...
%         = thresh_tool_dan_percent(thumb(:,:,channel));
    [minlevel,bw] ...
        = thresh_tool(thumb);

    thresh = minlevel;
    set(handles.edit_threshlo,'String',num2str(round(thresh)));

    userData.threshold = thresh;
    set(handles.figure1,'UserData',userData);
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
userData = get(handles.figure1, 'UserData');

if ~isfield(userData,'slideFile')
    errordlg('Load an image first','ERROR')
    set(handles.edit_dilateSE,'String','2');
    return
end


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
userData = get(handles.figure1, 'UserData');

if ~isfield(userData,'slideFile')
    errordlg('Load an image first','ERROR')
    set(handles.edit_erodeSE,'String','7');
    return
end


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
    errordlg('Load a slide image first','ERROR')
    return
elseif ~isfield(userData,'thumbNailFile')
    errordlg('Load a slide image first','ERROR')
    return    
else
        
    fname = userData.slideFile;

    threshlo = str2double(get(handles.edit_threshlo,'String'));

    meta = imreadImarismeta(fname,0);
    slideSize(1,1) = meta.height;
    slideSize(1,2) = meta.width;

    thumb = userData.thumbNailIm;
    choices{1,1} = userData.dilateim;
    choices{1,2} = userData.closeim;
    choices{1,3} = userData.erodeim;
    thumbSize = size(thumb);
    thumbSize = thumbSize(1,1:2);

    scale = double(thumbSize) ./ double(slideSize);
    mode = userData.ImageMode;

    dil(1) = str2double(get(handles.edit_iterDilate,'String'));
    dil(2) = str2double(get(handles.edit_dilateSE,'String'));
    ero(1) = str2double(get(handles.edit_iterErode,'String'));
    ero(2) = str2double(get(handles.edit_erodeSE,'String'));
    BWopen = SlideSegmentation(thumb,mode,choices,1,threshlo,dil,ero,400);

    % create new connected components list for filtered objects
    cc2keep = bwconncomp(BWopen);
    L2keep = labelmatrix(cc2keep);
    s = regionprops(cc2keep, 'PixelIdxList', 'Centroid','BoundingBox');

    section_map = ind2rgb(L2keep,jet(16));
%     hSP = userData.scrollhandle;
%     api = iptgetapi(hSP);
%     api.replaceImage(section_map,'DisplayRange',[0 255],'PreserveView',1);
    set(handles.figure1,'CurrentAxes',handles.axes1);
    imagesc(section_map);axis off;

    %label the objects
    hold on
    for k = 1:numel(s)
        x = s(k).Centroid(1);
        y = s(k).Centroid(2);
        text(x, y, sprintf('%d',k), 'Color', 'r', ...
            'FontWeight', 'bold');
        ROIdispbox(k,:) = (s(k).BoundingBox);

        % and create the ROIs
        ROI(k,:) = (s(k).BoundingBox);
        ROIslide(k,1) = floor(ROI(k,1) ./ scale(2));
        ROIslide(k,2) = floor(ROI(k,2) ./ scale(1));
        ROIslide(k,3) = floor((ROI(k,3))./ scale(2));
        dw = floor(ROIslide(k,3) .* 0.1);
        ROIslide(k,3) = ROIslide(k,3) + dw;
        ROIslide(k,4) = floor((ROI(k,4))./ scale(1));
        dh = floor(ROIslide(k,4) .* 0.05);
        ROIslide(k,4) = ROIslide(k,4) + dh;   
    end
    x = ROIdispbox(1,1);
    y = ROIdispbox(1,2);
    w = ROIdispbox(1,3);
    h = ROIdispbox(1,4);
    rectangle('Position',[x,y,w,h],'EdgeColor','r')
    hold off

    userData.AutoSections = s;
    userData.ROI.autoloc = ROIslide;
    userData.section_map = section_map;
    userData.slideSize = slideSize;
    set(handles.figure1,'UserData',userData);        
    set(handles.text_numROIs,'String',strcat('Number of sections = ',num2str(numel(s))));
    set(handles.text_numROIs,'Visible','on');
    set(handles.listbox_ROIs,'Visible','on');
    set(handles.listbox_ROIs,'String',num2str(ROIslide),'Value',1);
    set(handles.popupmenu_scale,'String',{'Output scale','1','2','4','8','16'},'Value',2);

end

% --- Executes on button press in pushbutton_clearROIs.
function pushbutton_clearROIs_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clearROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1,'UserData');

if ~isfield(userData,'thumbNailFile')
    errordlg('Load a thumbnail image first','ERROR')
    return
else
    userData.ROI.roicounter = 0;
    set(handles.figure1,'CurrentAxes',handles.axes1);
    thumb = userData.thumbNailIm;
%     hSP = userData.scrollhandle;
%     api = iptgetapi(hSP);
%     api.replaceImage(thumb,'DisplayRange',[0 255],'PreserveView',1);
    imagesc(thumb);colormap gray;axis off;
    set(handles.listbox_ROIs,'Visible','off');
    set(handles.text_numROIs,'Visible','off');
    userData.ROI.display = [];
    userData.ROI.manualloc = [];  
    userData.ROI.autoloc = []; 
    set(handles.figure1,'UserData',userData);
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
    errordlg('Load an image first','ERROR')
    return
else
    pos = get(hObject,'Value');
    imseg = userData.imseg;
   
    hold on
    set(handles.figure1,'CurrentAxes',handles.axes1);
    switch imseg
        case 'auto'
            section_map = userData.section_map;
            imagesc(section_map);axis off;

            %label the objects
            s = userData.AutoSections;
            for k = 1:numel(s)
                x = s(k).Centroid(1);
                y = s(k).Centroid(2);
                text(x, y, sprintf('%d',k), 'Color', 'r', ...
                    'FontWeight', 'bold');
                ROI(k,:) = (s(k).BoundingBox);
            end
            userData.ROI.usrSelecAuto = pos;
        case 'man'
            section_map = userData.thumbNailIm;
            ROI = userData.ManSections;
            imagesc(section_map);axis off;
            for k = 1:size(ROI,1)
                xtext = ROI(k,1) + ROI(k,3) ./ 2;
                ytext = ROI(k,2) + ROI(k,4) ./ 2;
                text(xtext, ytext, sprintf('%d',k), 'Color', 'r', ...
                    'FontWeight', 'bold');
            end
            userData.ROI.usrSelecMan = pos;
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
set(handles.figure1,'UserData',userData);

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
userData = get(handles.figure1, 'UserData');

if ~isfield(userData,'slideFile')
    errordlg('Load an image first','ERROR')
    set(handles.edit_channel,'String','1');
    return
else
    fname = userData.slideFile;

    thumbmeta = imreadImarismeta(fname,5);
    thumbSize(1,1) = thumbmeta.height;
    thumbSize(1,2) = thumbmeta.width;
    numchan = userData.inChannels;
    channel = str2double(get(handles.edit_channel,'String'));
    if channel > numchan || channel <=0
        errordlg('The channel does not exist in the input image','ERROR')
        return
    end

    thumb = imreadImaris(fname,thumbSize,5,1,1,channel);

    set(handles.figure1,'CurrentAxes',handles.axes1)
    imagesc(thumb);axis off;

    userData.thumbNailIm = thumb;
end
set(handles.figure1, 'UserData', userData);

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

popupselec = get(handles.popupmenu_scale,'Value');
popupcontents = cellstr(get(handles.popupmenu_scale,'String'));
scalefact = str2num(popupcontents{popupselec});
if isempty(scalefact)
    reslevel = 1;
else
    reslevel = log2(scalefact);
end

imseg = userData.imseg;
if isfield(userData.ROI,'autoloc') || isfield(userData.ROI,'manualloc')
    switch imseg
        case 'auto'
            ROI = userData.ROI.autoloc;
        case'man'
            ROI = userData.ROI.manualloc;
    end
    fname = userData.slideFile;
    slideSize = userData.slideSize;
    meta = imreadImarismeta(fname,reslevel);
    thumbSize(1,1) = meta.height;
    thumbSize(1,2) = meta.width;

    scale = double(thumbSize) ./ double(slideSize);

    for k = 1:size(ROI,1)
        ROIslide(k,1) = floor(ROI(k,1) .* scale(2));
        ROIslide(k,2) = floor(ROI(k,2) .* scale(1));
        ROIslide(k,3) = floor(ROI(k,3) .* scale(2));
        ROIslide(k,4) = floor(ROI(k,4) .* scale(1));
    end

    set(handles.listbox_ROIs,'Visible','on');
    set(handles.listbox_ROIs,'String',num2str(ROIslide),'Value',1);
    userData.ROI.scaled = ROIslide;
end
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
userData = get(handles.figure1, 'UserData');

if ~isfield(userData,'slideFile')
    errordlg('Load an image first','ERROR')
    set(handles.edit_outchan,'String','1');
    return
end


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



function edit_iterDilate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_iterDilate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_iterDilate as text
%        str2double(get(hObject,'String')) returns contents of edit_iterDilate as a double
userData = get(handles.figure1, 'UserData');

if ~isfield(userData,'slideFile')
    errordlg('Load an image first','ERROR')
    set(handles.edit_iterDilate,'String','1');
    return
end


% --- Executes during object creation, after setting all properties.
function edit_iterDilate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_iterDilate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_iterErode_Callback(hObject, eventdata, handles)
% hObject    handle to edit_iterErode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_iterErode as text
%        str2double(get(hObject,'String')) returns contents of edit_iterErode as a double
userData = get(handles.figure1, 'UserData');

if ~isfield(userData,'slideFile')
    errordlg('Load an image first','ERROR')
    set(handles.edit_iterErode,'String','1');
    return
end


% --- Executes during object creation, after setting all properties.
function edit_iterErode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_iterErode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes when selected object is changed in uipanel_improc.
function uipanel_improc_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_improc 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1, 'UserData');
set(handles.popupmenu_scale,'String',{'Output scale','1','2','4','8','16'},'Value',2);

if ~isfield(userData,'slideFile')
    errordlg('Load an image first','ERROR')
    set(handles.radiobutton_man,'Value',0.0);
    set(handles.radiobutton_auto,'Value',1.0);
    return
else
    switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
        case 'radiobutton_auto'
            userData.imseg = 'auto';
            if isfield(userData,'section_map')
                section_map = userData.section_map;
            else
                section_map = userData.thumbNailIm;
            end
            set(handles.figure1,'CurrentAxes',handles.axes1);
            imagesc(section_map);axis off;

            if isfield(userData.ROI,'autoloc')
                if isfield(userData.ROI,'usrSelecAuto')
                    pos = userData.ROI.usrSelecAuto;
                else
                    pos = 1;
                end
                ROIslide = userData.ROI.autoloc;
                s = userData.AutoSections;
                hold on
                for k = 1:numel(s)
                    x = s(k).Centroid(1);
                    y = s(k).Centroid(2);
                    text(x, y, sprintf('%d',k), 'Color', 'r', ...
                        'FontWeight', 'bold');
                    ROI(k,:) = (s(k).BoundingBox);
                end
                x = ROI(pos,1);
                y = ROI(pos,2);
                w = ROI(pos,3);
                h = ROI(pos,4);
                rectangle('Position',[x,y,w,h],'EdgeColor','r');
                hold off
            else
                ROIslide = [];
                pos = 1;
            end
            set(handles.listbox_ROIs,'Visible','on');
            set(handles.listbox_ROIs,'String',num2str(ROIslide),'Value',pos);            
            set(handles.pushbutton_processThumb,'Visible','on');
            set(handles.pushbutton_manual,'Visible','off');
            set(handles.togglebutton_DrawROI,'Visible','off');
            set(handles.text1,'Visible','on');
            set(handles.edit_threshlo,'Visible','on');
            set(handles.pushbutton_setThresh,'Visible','on');
            set(handles.checkbox_close,'Visible','on');
            set(handles.checkbox_dilate,'Visible','on');
            set(handles.text2,'Visible','on');
            set(handles.edit_dilateSE,'Visible','on');
            set(handles.text8,'Visible','on');
            set(handles.edit_iterDilate,'Visible','on');
            set(handles.checkbox_erode,'Visible','on');
            set(handles.text3,'Visible','on');
            set(handles.edit_erodeSE,'Visible','on');
            set(handles.text9,'Visible','on');
            set(handles.edit_iterErode,'Visible','on');
            
        case 'radiobutton_man'
            userData.imseg = 'man';
                        
            set(handles.figure1,'CurrentAxes',handles.axes1);
            thumb = userData.thumbNailIm;
            imagesc(thumb);axis off;
            
            if isfield(userData.ROI,'manualloc')
                if isfield(userData.ROI,'usrSelecMan')
                    pos = userData.ROI.usrSelecMan;
                else
                    pos = 1;
                end
                ROIslide = userData.ROI.manualloc;
                s = userData.ROI.ManSections;
                hold on
                for k = 1:size(ROIslide,1)
                    xtext = s(k,1) + s(k,3) ./ 2;
                    ytext = s(k,2) + s(k,4) ./ 2;
                    text(xtext, ytext, sprintf('%d',k), 'Color', 'r', ...
                        'FontWeight', 'bold');
                end
                x = s(pos,1);
                y = s(pos,2);
                w = s(pos,3);
                h = s(pos,4);
                rectangle('Position',[x,y,w,h],'EdgeColor','r');
                hold off

            else
                ROIslide = [];
                pos = 1;
            end
            set(handles.listbox_ROIs,'Visible','on');
            set(handles.listbox_ROIs,'String',num2str(floor(ROIslide)),'Value',pos);


            set(handles.pushbutton_processThumb,'Visible','off');
            set(handles.text_numROIs,'Visible','off');
            set(handles.pushbutton_manual,'Visible','on');
            set(handles.togglebutton_DrawROI,'Visible','on');
            set(handles.text1,'Visible','off');
            set(handles.edit_threshlo,'Visible','off');
            set(handles.pushbutton_setThresh,'Visible','off');
            set(handles.checkbox_close,'Visible','off');
            set(handles.checkbox_dilate,'Visible','off');
            set(handles.text2,'Visible','off');
            set(handles.edit_dilateSE,'Visible','off');
            set(handles.text8,'Visible','off');
            set(handles.edit_iterDilate,'Visible','off');
            set(handles.checkbox_erode,'Visible','off');
            set(handles.text3,'Visible','off');
            set(handles.edit_erodeSE,'Visible','off');
            set(handles.text9,'Visible','off');
            set(handles.edit_iterErode,'Visible','off');


    end
end
set(handles.figure1, 'UserData', userData);


% --- Executes on button press in pushbutton_selectfiles.
function pushbutton_selectfiles_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_selectfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1,'UserData');
set(handles.text_cropslide,'Visible','off');
files = uipickfiles('FilterSpec','*.ims','out','struct'); %external fuction
filenames = {files.name};
numfiles = length(filenames);
fname = filenames{1};
A = findstr('/',fname);
B = length(A);
C = A(B);
impath = fname(1:C);
cd(impath);
userData.Batch.filenames = filenames;
set(handles.figure1,'UserData',userData);

% --- Executes on button press in pushbutton_batch.
function pushbutton_batch_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_batch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1,'UserData');
if ~isfield(userData,'slideFile')
    errordlg('You should load a single file and setup the segmentation settings first','ERROR')
    return
end

if ~isfield(userData,'Batch')
    errordlg('Choose images for batch processing','ERROR')
    return
else
    filenames = userData.Batch.filenames;
    numfiles = length(filenames);
    for iFile = 1: numfiles
        fname = filenames{iFile};
        set(handles.text_cropslide,'Visible','on');
        cropslideStr = [sprintf('Cropping slide %d',iFile),' of ',sprintf('%d',numfiles)];
        set(handles.text_cropslide,'String',cropslideStr);
        threshlo = str2double(get(handles.edit_threshlo,'String'));
        channel = str2double(get(handles.edit_channel,'String'));
        
        popupselec = get(handles.popupmenu_scale,'Value');
        popupcontents = cellstr(get(handles.popupmenu_scale,'String'));
        scalefact = str2num(popupcontents{popupselec});
        if scalefact
            reslevel = log2(scalefact);
        else
            reslevel = 0;
        end

        meta = imreadImarismeta(fname,reslevel);
        slideSize(1,1) = meta.height;
        slideSize(1,2) = meta.width;
        numChan = meta.channels;
        
        thumbmeta = imreadImarismeta(fname,5);
        thumbSize(1,1) = thumbmeta.height;
        thumbSize(1,2) = thumbmeta.width;
        thumb = imreadImaris(fname,thumbSize,5,1,1,channel);
        
        choices{1,1} = userData.dilateim;
        choices{1,2} = userData.closeim;
        choices{1,3} = userData.erodeim;

        scale = double(thumbSize) ./ double(slideSize);
        
        mode = userData.ImageMode;

        dil(1) = str2double(get(handles.edit_iterDilate,'String'));
        dil(2) = str2double(get(handles.edit_dilateSE,'String'));
        ero(1) = str2double(get(handles.edit_iterErode,'String'));
        ero(2) = str2double(get(handles.edit_erodeSE,'String'));
        
        BWopen = SlideSegmentation(thumb,mode,choices,1,threshlo,dil,ero,400);

        % create new connected components list for filtered objects
        cc2keep = bwconncomp(BWopen);
        s = regionprops(cc2keep, 'PixelIdxList', 'Centroid','BoundingBox');

        %label the objects
        for k = 1:numel(s)
            % and create the ROIs
            ROI(k,:) = (s(k).BoundingBox);
            ROIslide(k,1) = floor(ROI(k,1) ./ scale(2));
            ROIslide(k,2) = floor(ROI(k,2) ./ scale(1));
            ROIslide(k,3) = floor((ROI(k,3))./ scale(2));
            dw = floor(ROIslide(k,3) .* 0.1);
            ROIslide(k,3) = ROIslide(k,3) + dw;
            ROIslide(k,4) = floor((ROI(k,4))./ scale(1));
            dh = floor(ROIslide(k,4) .* 0.05);
            ROIslide(k,4) = ROIslide(k,4) + dh;        
        end
        
        mode = userData.OutputMode;
        contents = 1:size(ROIslide,1);

        switch mode
            case 'RGB'
                    outChan = 1:3;
                    inChan = 1:numChan;
            case 'Single'
                    outChan = str2double(get(handles.edit_outchan,'String'));  
                    if outChan > numChan
                        errordlg('The channel does not exist in the input image','ERROR')
                        return
                    else
                        inChan = outChan;
                    end
        end

        sectionImWrite(fname,ROIslide,numChan,inChan,outChan,contents,reslevel)

        
    end
    
end


% --- Executes on button press in togglebutton_DrawROI.
function togglebutton_DrawROI_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_DrawROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_DrawROI
userData = get(handles.figure1, 'UserData');
if ~isfield(userData,'slideFile')
    errordlg('Load an image first','ERROR')
    return
else
    set(handles.popupmenu_scale,'String',{'Output scale','1','2','4','8','16'},'Value',2);
    set(handles.figure1,'CurrentAxes',handles.axes1);
    thumb = userData.thumbNailIm;
    hold on
    imagesc(thumb);axis off;
    if isfield(userData.ROI,'ROIdisplay')
        ROIdisp = userData.ROI.ROIdisplay;
        for k = 1:size(ROIdisp,1)

            x = ROIdisp(k,1);
            y = ROIdisp(k,2);
            w = ROIdisp(k,3);
            h = ROIdisp(k,4);
            rectangle('Position',[x y w h],'EdgeColor','r');

        end
    end
    hold off
    thumbSize = size(thumb);
    imrow = thumbSize(1,1);
    imcol = thumbSize(1,2);
    % How many ROI's are already in existence?
    % Draw the ROI and get centroid pos and area
    set(handles.figure1,'CurrentAxes',handles.axes1);
    hrectROI = imrect(handles.axes1);

    ROIapi = iptgetapi(hrectROI);
    ROIapi.addNewPositionCallback(@(p) disp(p));
    fcn = makeConstrainToRectFcn('imrect',[1 imcol],[1 imrow]);
    setPositionConstraintFcn(hrectROI,fcn);

    userData.ROI.recthandle = hrectROI;
end
set(handles.figure1, 'UserData', userData);


% --- Executes during object creation, after setting all properties.
function pushbutton_manual_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton_manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in pushbutton_manual.
function pushbutton_manual_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.figure1, 'UserData');
if ~isfield(userData,'slideFile')
    errordlg('Load an image first','ERROR')
    return
else
    set(handles.popupmenu_scale,'String',{'Output scale','1','2','4','8','16'},'Value',2);
    set(handles.figure1,'CurrentAxes',handles.axes1);
    thumb = userData.thumbNailIm;
    hold on
    %imagesc(thumb);axis off;
    if isfield(userData.ROI,'recthandle')

        hrectROI = userData.ROI.recthandle;
        position = getPosition(hrectROI);
        ROIpos = position(end,:);
        
        thumbSize = size(thumb);
        slideSize = userData.slideSize;
        scale = thumbSize ./ slideSize;

        % How many ROI's are already in existence?
        iROI = userData.ROI.roicounter;
        if isfield(userData.ROI,'manualloc');
            ROIslide = userData.ROI.manualloc;
            ROIdisp = userData.ROI.ROIdisplay;
        end        
        % Draw the ROI and get centroid pos and area
        set(handles.figure1,'CurrentAxes',handles.axes1);

        iROI = iROI + 1;
        ROIdisp(iROI,1) = floor(ROIpos(1,1));
        ROIdisp(iROI,2) = floor(ROIpos(1,2));
        ROIdisp(iROI,3) = floor(ROIpos(1,3));
        ROIdisp(iROI,4) = floor(ROIpos(1,4));

        ROIslide(iROI,1) = floor(ROIpos(1,1) ./ scale(2));
        ROIslide(iROI,2) = floor(ROIpos(1,2) ./ scale(1));
        ROIslide(iROI,3) = floor((ROIpos(1,3))./ scale(2));
        dw = floor(ROIslide(iROI,3) .* 0.1);
        ROIslide(iROI,3) = ROIslide(iROI,3) + dw;
        ROIslide(iROI,4) = floor((ROIpos(1,4))./ scale(1));
        dh = floor(ROIslide(iROI,4) .* 0.05);
        ROIslide(iROI,4) = ROIslide(iROI,4) + dh;

        for k = 1:size(ROIdisp,1)

            x = ROIdisp(k,1);
            y = ROIdisp(k,2);
            w = ROIdisp(k,3);
            h = ROIdisp(k,4);
            rectangle('Position',[x y w h],'EdgeColor','r');

        end
    end
    hold off
    
    set(handles.listbox_ROIs,'Visible','on');
    set(handles.listbox_ROIs,'String',num2str(ROIslide),'Value',1);
    set(handles.text_numROIs,'String',strcat('Number of sections =  ',num2str(size(ROIslide,1))));
    set(handles.text_numROIs,'Visible','on');
    userData.ROI.manualloc = ROIslide;
    userData.ROI.ROIdisplay = ROIdisp;
    userData.ROI.roicounter = iROI;
end
set(handles.figure1, 'UserData', userData);


% --- Executes on button press in pushbutton_cancelbatch.
function pushbutton_cancelbatch_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cancelbatch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cancelflag = 1;
while cancelflag == 1
    choice = questdlg('Are you sure you want to cancel the process?', ...
     'Image overwrite','Yes','No','No');
    % Handle response
    switch choice
        case 'Yes'
            cancelflag = 0;
            return
            %break
        case 'No'
            continue
    end
end
