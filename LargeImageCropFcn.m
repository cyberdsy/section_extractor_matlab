function [ROIout BoundingBox] = LargeImageCropFcn(new_data,location,BlockSize,BoundingBox)

if ~isempty(new_data)
% Set up the large image and how many blocks it should have
    data = zeros(size(new_data,1),size(new_data,2),size(new_data,3));
    for ii = 1:size(new_data,3)
        data(:,:,ii) = new_data(:,:,ii);
    end
    
    StartInBlock = [1 1];
    EndInBlock = [1 1];
     %location
    % Set up the region of interest to crop
    BoundingBoxStart = floor(BoundingBox(1:2));
    BoundingBoxEnd(1) = BoundingBoxStart(1) + floor(BoundingBox(3));
    BoundingBoxEnd(2) = BoundingBoxStart(2) + floor(BoundingBox(4));
    % Find out the start and end positions of the Bounding Box relative to the block
    % start positions
    
    if BoundingBoxStart(1) == location(1)
        StartInBlock(1) = 1;
    else
        StartInBlock(1) = BoundingBoxStart(1) - location(1) + 1;
    end
    
    if BoundingBoxStart(2) == location(2)
        StartInBlock(2) = 1;
    else
        StartInBlock(2) = BoundingBoxStart(2) - location(2) + 1;
    end
    
    EndInBlock(1) = BoundingBoxEnd(1) - location(1) + 1;
    EndInBlock(2) = BoundingBoxEnd(2) - location(2) + 1;

    % Now find out if the Bounding Box overlaps with the current block
    % check if the start in block value from above is -ve and see if
    % the absolute value of the ROI.
    % If the start points are +ve and less than the block size then the
    % start point must lie within the block so keep the values. If the
    % start point is -ve then the start point relative to the block must be
    % on the block boundary so make this value 1

    if StartInBlock(1) < 0
        %check the absolute value and see if it is greater than the
        %size of the bounding box
        if abs(StartInBlock(1)) > BoundingBox(3) 
            StartInBlock(1) = NaN;
        else
            StartInBlock(1) = 1;
        end
    end

    if StartInBlock(2) < 0
        if abs(StartInBlock(2)) > BoundingBox(4)
            StartInBlock(2) = NaN;
        else
            StartInBlock(2) = 1;
        end
    end

    if StartInBlock(1) > BlockSize(1)
        %check the absolute value and see if it is greater than the
        %size of the bounding box
        if StartInBlock(1) > BoundingBox(3)
            StartInBlock(1) = NaN;
        end                
    end

    if StartInBlock(2) > BlockSize(2)
        if StartInBlock(2) > BoundingBox(4)
            StartInBlock(2) = NaN;
        end
    end
    
    StartPoint = StartInBlock;    
    
    EndPoint = EndInBlock;
    
    %if the end point is greater than the block size (i.e. the end point
    %lies outside the block) then subtract the size of the bounding box
    SizeInBlk = zeros(1,2);
    
    if abs(EndPoint(1)) > BlockSize(1)
        if abs(EndPoint(1)) > BoundingBoxEnd(1)
            SizeInBlk(1) = 1;
        else
            SizeInBlk(1) = BlockSize(1) - StartPoint(1) + 1;
        end
    else
        SizeInBlk(1) = EndPoint(1);
    end

    if abs(EndPoint(2)) > BlockSize(2)        
        if abs(EndPoint(2)) > BoundingBoxEnd(2)
            SizeInBlk(2) = 1;
        else
            SizeInBlk(2) = BlockSize(2) - StartPoint(2) + 1;
        end
    else
        SizeInBlk(2) = EndPoint(2);
    end
    
    if BoundingBox(3) < BlockSize(1) && BoundingBox(4) < BlockSize(2)
        if BoundingBox(1) - location(1) > BlockSize(1) || BoundingBox(2) - location(2) > BlockSize(2)
            SizeInBlk(1) = NaN;
            SizeInBlk(2) = NaN;
        else
            SizeInBlk(1) = BoundingBox(3);
            SizeInBlk(2) = BoundingBox(4);
        end
    end

    if SizeInBlk(1) <= 0 
        SizeInBlk(1) = NaN;
    end
    
    if SizeInBlk(2) <= 0
        SizeInBlk(2) = NaN;
    end

    if abs(SizeInBlk(1)) == 1
        SizeInBlk(1) = NaN;
    end
    
    if abs(SizeInBlk(2)) == 1
        SizeInBlk(2) = NaN;
    end
    
    if ~isnan(SizeInBlk(1,1)) && ~isnan(SizeInBlk(1,2))
        Start = StartPoint;
        SizeInBlk;
        ROI = zeros(SizeInBlk(1),SizeInBlk(2),size(data,3));
        for ii = 1:size(data,3)
            ROI(:,:,ii) = data(StartPoint(1):(StartPoint(1) + SizeInBlk(1) - 1),...
               StartPoint(2):(StartPoint(2) + SizeInBlk(2) - 1),ii);
           ROIout = uint8(ROI);
        end
%        figure;imagesc(ROI(:,:,1));colormap gray;
%        figure;imagesc(ROI(:,:,2));colormap gray;

    else
        Start = [];
        ROIout = [];
    end
else
    ROIout = [];
end
clear ROI