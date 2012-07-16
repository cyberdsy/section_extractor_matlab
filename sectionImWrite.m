function sectionImWrite(slideFile,ROIvec,numChan,inChan,outChan,contents,reslevel)

    fname_length = length(slideFile);
    slideFilename = slideFile(1:fname_length - 4);

    blocksize = [2000 2000];

    my_adapter = ImarisROIAdapter(slideFile,'r',reslevel,inChan);

    tic

    %Loop over identified tissue sections. This part can be modified. Set the
    %index iImage to 1 to segment a single section. Set it to any integer value
    %between 1 and the length of idx to select a single section from the list
    %of coordinates in bounding box. Or set values of ROI if these are known
    %and make iImage = 1 (ROI = [x y width height].
    for iSection = contents
        % Crop a portion of the image set by the bounding box
        ROI = ROIvec(iSection,:);
        outImageSize = [floor(ROI(4)) floor(ROI(3)) length(outChan)];

        % make filename for each tissue section
        if iSection < 10
            tiss_seq_tif = sprintf([slideFilename,'section_00%d.tif'],iSection);
        elseif iSection >= 10 && iSection < 100
            tiss_seq_tif = sprintf([slideFilename,'section_0%d.tif'],iSection);
        elseif iSection >= 100
            tiss_seq_tif = sprintf([slideFilename,'section_%d.tif'],iSection);
        end

        existflag = 2;
        while existflag == exist(tiss_seq_tif,'file')
            choice = questdlg('Image already exists. Do you want to overwrite?', ...
             'Image overwrite','Yes','No','No');
            % Handle response
            switch choice
                case 'Yes'
                    existflag = 0;
                case 'No'
                    [tiss_seq_tif,pathname] = uiputfile({'*.tif', 'TIFF Image File'; ...
                                    '*.*', 'All Files (*.*)'}, ...
                                    'Save current image as');
                    existflag = 1;
            end
        end

        if outImageSize(1) > blocksize(1) || outImageSize(2) > blocksize(2)
            %display tissue section name and ROI vector to command line
            tiss_seq_tif
            ROI
            pixRegion(1,1) = ROI(2);
            pixRegion(1,2) = ROI(1);
            pixRegion(1,3) = ROI(4);
            pixRegion(1,4) = ROI(3);

            %set up the output image size and cropping function
            imgCropFcn = @(block_struct) LargeImageCropFcn(block_struct.data,block_struct.location,blocksize,pixRegion);

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
            pixRegion(2) = ROI(2);
            pixRegion(3) = ROI(3);
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