function [vol]=imreadH5(datname,zplanes,tframes,NumChannels,PixelRegion)

imageInfo = '/DataSetInfo/Image';
width = h5readatt(datname,imageInfo,'X');
height = h5readatt(datname,imageInfo,'Y');

for iwidth = 1:length(width)
    X(iwidth) = width{iwidth};
end

for iheight = 1:length(height)
    Y(iheight) = height{iheight};
end


if nargin < 5 || isempty(PixelRegion)
    width = X;
    height = Y;
    ulX = 1;
    ulY = 1;
else
    if length(PixelRegion) == 4
        ulY = PixelRegion(1);
        height = PixelRegion(2);
        ulX = PixelRegion(3);
        width = PixelRegion(4);
    elseif length(PixelRegion) == 2
        ulY = 1;
        height = PixelRegion(1);
        ulX = 1;
        width = PixelRegion(2);
    else
        disp('PixelRegion input should be a vector of length 2 or 4');
        return
    end
end

zplane = zplanes-1;
tframe = tframes-1;



vol = zeros(height,width,length(zplane)*length(tframe));
zahler = 0;
location = '/DataSet/ResolutionLevel 0/TimePoint 0/Channel ';

    for j=1:length(tframe)
                        
        for i=1:NumChannels
            chanstr = [location,num2str(i-1),'/Data'];
            zahler = zahler+1;
            arr = h5read(datname,chanstr,[ulX ulY 1],[width height 1]);
            
            shape = [width height];
            I = reshape(arr, shape)';
            vol(:,:,zahler) = I;
            
        end

    end
    
end

    
            
            
            
            
            
  
            
            

        
   
   
   
   
   
            
            