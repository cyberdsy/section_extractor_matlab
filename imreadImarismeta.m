function meta=imreadImarismeta(datname,resLevel)

    imageInfo = '/DataSetInfo/Image';
    timeInfo = '/DataSetInfo/TimeInfo';
    
    location = ['/DataSet/ResolutionLevel ',num2str(resLevel),'/TimePoint 0/Channel 0/'];
    info = h5info(datname,location);
    imsize = info.Datasets(1).Dataspace.Size;
    
    width = imsize(1,1);
    height = imsize(1,2);
    zsize = h5readatt(datname,imageInfo,'Z');
    channels = h5readatt(datname,imageInfo,'Noc');
    nframes = h5readatt(datname,timeInfo,'DatasetTimePoints');

    
    for izsize = 1:length(zsize)
        Z(izsize) = zsize{izsize};
    end
    
    for ichan = 1:length(channels)
        C(ichan) = channels{ichan};
    end
    
    for itime = 1:length(nframes)
        T(itime) = nframes{itime};
    end
    
    meta.width = width;
    meta.height = height;
    meta.zsize = uint32(str2double(Z));
    meta.nframes = uint32(str2double(T));
    meta.channels = uint32(str2double(C));    

end         
  
            
            
   
        
   
   
   
   
   
            
            
            