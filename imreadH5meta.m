function meta=imreadH5meta(datname)

    imageInfo = '/DataSetInfo/Image';
    timeInfo = '/DataSetInfo/TimeInfo';
    
    width = h5readatt(datname,imageInfo,'X');
    height = h5readatt(datname,imageInfo,'Y');
    zsize = h5readatt(datname,imageInfo,'Z');
    channels = h5readatt(datname,imageInfo,'Noc');
    nframes = h5readatt(datname,timeInfo,'DatasetTimePoints');
    
    for iwidth = 1:length(width)
        X(iwidth) = width{iwidth};
    end
    
    for iheight = 1:length(height)
        Y(iheight) = height{iheight};
    end
    
    for izsize = 1:length(zsize)
        Z(izsize) = zsize{izsize};
    end
    
    for ichan = 1:length(channels)
        C(ichan) = channels{ichan};
    end
    
    for itime = 1:length(nframes)
        T(itime) = nframes{itime};
    end
    
    meta.width = uint32(str2double(X));
    meta.height = uint32(str2double(Y));
    meta.zsize = uint32(str2double(Z));
    meta.nframes = uint32(str2double(T));
    meta.channels = uint32(str2double(C));    

end         
  
            
            
   
        
   
   
   
   
   
            
            
            