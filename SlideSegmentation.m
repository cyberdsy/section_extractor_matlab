function BWopen = SlideSegmentation(im,mode,choices,channel,threshlo,dil,ero,sizeFilt)
    dilateim = choices{1,1};
    closeim = choices{1,2};
    erodeim = choices{1,3};
    switch mode
        case 'bright'
            BW = im(:,:,channel) < threshlo;
        case 'fluoro'
            BW = im(:,:,channel) > threshlo;
    end

    if dilateim
        dilIter = dil(1);
        for idil = 1 : dilIter
            dilSize = dil(2);
            se = strel('disk',dilSize);
            BWdil = imdilate(BW,se);
            BW = BWdil;
        end
    else
        BWdil = BW;
    end

    if closeim
        BWclose = imfill(BWdil,'holes');
    else
        BWclose = BWdil;
    end

    if erodeim
        eroIter = ero(1);
        for iero = 1 : eroIter
            eroSize = ero(2);
            se = strel('disk',eroSize);
            BWero = imerode(BWclose,se);
            BWclose = BWero;
        end
    else
        BWero = BWclose;
    end

    % find the connected components
    cc = bwconncomp(BWero);
    L = labelmatrix(cc);

    %filter by area to remove small objects
    stats = regionprops(L,'Area');
    idx = find([stats.Area]>sizeFilt);
    BWopen = ismember(L,idx);
end
