function [vol]=imreadBF(datname,zplanes,tframes,NumChannels,PixelRegion)
%[vol]=imreadBF(datname,zplanes,tframes,channel)
%
%imports images using the BioFormats package
%you can load multiple z and t slices at once, e.g. zplanes=[1 2 5] loads
%first,second and fifth z-slice in a 3D-Stack 
%
%if loading multiple z slices and tframes, everything is returned in one 3D
%Stack with order ZT. Only one channel can be imported at once
%
%use imreadBFmeta() to get corresponding metadata of the image file
%
%To use the function, you have to download loci_tools.jar here: http://www.loci.wisc.edu/bio-formats/downloads
%make sure to have copied the file loci_tools.jar, in the folder where the
%function is placed (or to your work folder)
%
%
%
% For static loading, you can add the library to MATLAB's class path:
%     1. Type "edit classpath.txt" at the MATLAB prompt.
%     2. Go to the end of the file, and add the path to your JAR file
%        (e.g., C:/Program Files/MATLAB/work/loci_tools.jar).
%     3. Save the file and restart MATLAB.
%
%modified from bfopen.m
%christoph moehl 2011, cmohl@yahoo.com



% locipath = fullfile(fileparts(mfilename('fullpath')), 'loci_tools.jar');
% javaaddpath(locipath);
% 
% if exist('lurawaveLicense')
%     locipath = fullfile(fileparts(mfilename('fullpath')), 'lwf_jsdk2.6.jar');
%     javaaddpath(locipath);
%     java.lang.System.setProperty('lurawave.license', lurawaveLicense);
% end

% check MATLAB version, since typecast function requires MATLAB 7.1+
canTypecast = versionCheck(version, 7, 1);

% check Bio-Formats version, since makeDataArray2D function requires trunk
bioFormatsVersion = char(loci.formats.FormatTools.VERSION);
isBioFormatsTrunk = versionCheck(bioFormatsVersion, 5, 0);

% initialize logging
%loci.common.DebugTools.enableLogging('INFO');


r = loci.formats.ChannelFiller();
r = loci.formats.ChannelSeparator(r);
r.setId(datname);

pixelType = r.getPixelType();

if nargin < 5 || isempty(PixelRegion)
    width = r.getSizeX();
    height = r.getSizeY();
    ulX = 0;
    ulY = 0;
else
    if length(PixelRegion) == 4
        ulY = PixelRegion(1);
        height = PixelRegion(2);
        ulX = PixelRegion(3);
        width = PixelRegion(4);
    elseif length(PixelRegion) == 2
        ulY = 0;
        height = PixelRegion(1);
        ulX = 0;
        width = PixelRegion(2);
    else
        disp('PixelRegion input should be a vector of length 2 or 4');
        return
    end
end

bpp = loci.formats.FormatTools.getBytesPerPixel(pixelType);
bppMax = power(2, bpp * 8);
fp = loci.formats.FormatTools.isFloatingPoint(pixelType);
little = r.isLittleEndian();
sgn = loci.formats.FormatTools.isSigned(pixelType);



channel=0:NumChannels-1;
zplane=zplanes-1;
tframe=tframes-1;



vol=zeros(height,width,length(zplane)*length(tframe));
zahler=0;
    for j=1:length(tframe)
        
        colorMaps = cell(NumChannels,1);
                
        for i=1:NumChannels
            

            %['importing file via bioFormats\\ ',num2str(100*zahler/(length(tframe)*length(zplane))),'%']
            index = r.getIndex(zplane,channel(i),tframe(j));
            plane = r.openBytes(index,ulX,ulY,width,height);
            zahler=zahler+1;
            
            % retrieve color map data
            if bpp == 1
                colorMaps{i} = r.get8BitLookupTable()';
            else
                colorMaps{i} = r.get16BitLookupTable()';
            end
            
            warning('off')
            if ~isempty(colorMaps{i})
                newMap = colorMaps{i};
                m = newMap < 0;
                newMap(m) = newMap(m) + bppMax;
                colorMaps{i} = newMap / (bppMax - 1);
            end
            warning('on')

            
            % convert byte array to MATLAB image
            if isBioFormatsTrunk && (sgn || ~canTypecast)
                % can get the data directly to a matrix
                arr = loci.common.DataTools.makeDataArray2D(plane, ...
                    bpp, fp, little, height);
            else
                % get the data as a vector, either because makeDataArray2D
                % is not available, or we need a vector for typecast
                arr = loci.common.DataTools.makeDataArray(plane, ...
                    bpp, fp, little);
            end
            %     if ~strcmp(class(I),class(arr)), I= cast(I,['u' class(arr)]); end

            % Java does not have explicitly unsigned data types;
            % hence, we must inform MATLAB when the data is unsigned
            if ~sgn
                if canTypecast
                    % TYPECAST requires at least MATLAB 7.1
                    % NB: arr will always be a vector here
                    switch class(arr)
                        case 'int8'
                            arr = typecast(arr, 'uint8');
                        case 'int16'
                            arr = typecast(arr, 'uint16');
                        case 'int32'
                            arr = typecast(arr, 'uint32');
                        case 'int64'
                            arr = typecast(arr, 'uint64');
                    end
                else
                    % adjust apparent negative values to actual positive ones
                    % NB: arr might be either a vector or a matrix here
                    mask = arr < 0;
                    adjusted = arr(mask) + bppMax / 2;
                    switch class(arr)
                        case 'int8'
                            arr = uint8(arr);
                            adjusted = uint8(adjusted);
                        case 'int16'
                            arr = uint16(arr);
                            adjusted = uint16(adjusted);
                        case 'int32'
                            arr = uint32(arr);
                            adjusted = uint32(adjusted);
                        case 'int64'
                            arr = uint64(arr);
                            adjusted = uint64(adjusted);
                    end
                    adjusted = adjusted + bppMax / 2;
                    arr(mask) = adjusted;
                end
            end

            if isvector(arr)
                % convert results from vector to matrix
                shape = [width height];
                I = reshape(arr, shape)';
                vol(:,:,zahler) = I;
            end

        end

    end
    
end

    
            
            
            
            
            
  
            
            

        
   
   
   
   
   
            
            