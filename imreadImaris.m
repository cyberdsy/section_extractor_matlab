function vol = imreadImaris(datname,imageSize,reslevel,zplanes,tframes,Channels,PixelRegion)
    
    X = imageSize(1,2);
    Y = imageSize(1,1);


    if nargin < 7 || isempty(PixelRegion)
        width = X;
        height = Y;
        ulX = 1;
        ulY = 1;
    else
        if length(PixelRegion) == 4
            ulX = PixelRegion(1);
            ulY = PixelRegion(2);
            width = PixelRegion(3);
            height = PixelRegion(4);
        elseif length(PixelRegion) == 2
            ulX = 1;
            ulY = 1;
            width = PixelRegion(3);
            height = PixelRegion(4);
            
        else
            disp('PixelRegion input should be a vector of length 2 or 4');
            return
        end
    end

    zplane = zplanes-1;
    tframe = tframes-1;

    vol = zeros(height,width,length(zplane)*length(tframe));
    
    zahler = 0;
    location = ['/DataSet/ResolutionLevel ',num2str(reslevel),'/TimePoint 0/Channel '];
    
    for j=1:length(tframe)
                        
        for i = Channels
            
            chanstr = [location,num2str(i-1),'/Data'];
            zahler = zahler+1;
            arr = h5read(datname,chanstr,[ulX ulY 1],[width height 1]);
            
            shape = [width height];
            I = reshape(arr, shape)';
            vol(:,:,zahler) = I;
        end

    end

end

    
            
            
            
            
            
  
            
            

        
   
   
   
   
   
            
            