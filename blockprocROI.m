function result_image = blockprocROI(source,block_size,fun,varargin)
%BLOCKPROC Distinct block processing for image.
%   B = BLOCKPROC(A,[M N],FUN) processes the image A by applying the
%   function FUN to each distinct M-by-N block of A and concatenating the
%   results into the output matrix B.  FUN is a function handle to a
%   function that accepts a "block struct" as input and returns a matrix,
%   vector, or scalar Y:
%
%       Y = FUN(BLOCK_STRUCT)
%
%   For each block of data in the input image, A, BLOCKPROC will pass the
%   block in a "block struct" to the user function, FUN, to produce Y, the
%   corresponding block in the output image.  If Y is empty, then no output
%   is generated and BLOCKPROC returns empty after processing all blocks.
%
%   A "block struct" is a MATLAB structure that contains the block data as
%   well as other information about the block.  Fields in the block struct
%   are:
%
%       BLOCK_STRUCT.border : a 2-element vector, [V H], that specifies the
%                             size of the vertical and horizontal padding
%                             around the block of data (see 'BorderSize'
%                             argument below).
%
%       BLOCK_STRUCT.blockSize : a 2-element vector, [rows cols],
%                                specifying the size of the block data. If
%                                a border has been specified, the size does
%                                not include the border pixels.
%
%       BLOCK_STRUCT.data : M-by-N or M-by-N-by-P matrix of block data plus
%                           any included border pixels.
%
%       BLOCK_STRUCT.imageSize : a 2-element vector, [rows cols],
%                                specifying the full size of the input
%                                image.
%
%       BLOCK_STRUCT.location : a 2-element vector, [row col], that
%                               specifies the position of the first pixel
%                               (minimum-row, minimum-column) of the block
%                               data in the input image.  If a border has
%                               been specified, the location refers to the
%                               first pixel of the discrete block data, not
%                               the added border pixels.
%
%   B = BLOCKPROC(SRC_FILENAME,[M N],FUN) processes the image specified by
%   SRC_FILENAME, reading and processing one block at a time.  This syntax
%   is useful for processing very large images since only one block of the
%   image is read into memory at a time.  If the output matrix B is too
%   large to fit into memory, then you should additionally use the
%   'Destination' parameter/value pair to write the output to a file.  See
%   below for information on supported file types and parameters.
%
%   B = BLOCKPROC(ADAPTER,[M N],FUN) processes the source image specified
%   by ADAPTER, an ImageAdapter object.  ImageAdapters are user-defined
%   classes that provide BLOCKPROC with a common API for reading and
%   writing to a particular image file format.  See the documentation for
%   ImageAdapter for more details.
%
%   BLOCKPROC(...,PARAM1,VAL1,PARAM2,VAL2,...) processes the input image,
%   specifying parameters and corresponding values that control various
%   aspects of the block behavior.  Parameter name case does not matter.
%
%   Parameters include:
%
%   'Destination'       The destination for the output of BLOCKPROC.  When
%                       specified, BLOCKPROC will not return the processed
%                       image as an output argument, but instead write the
%                       output to the 'Destination'.  Valid 'Destination'
%                       parameters are:
%
%                          TIFF filename: a string filename ending with
%                             '.tif'.  This file will be overwritten if it
%                             exists.
%
%                          ImageAdapter object: an instance of an
%                             ImageAdapter class.  ImageAdapters provide an
%                             interface for reading and writing to
%                             arbitrary image file formats.  See the
%                             documentation for ImageAdapter for more
%                             information.
%
%                       The 'Destination' parameter is useful when you
%                       expect your output to be too large to practically
%                       fit into memory.  It provides a workflow for
%                       file-to-file image processing for arbitrarily large
%                       images.
%
%   'BorderSize'        A 2-element vector, [V H], specifying the amount of
%                       border pixels to add to each block.  V rows are
%                       added above and below each block, H columns are
%                       added left and right of each block.  The size of
%                       each resulting block will be:
%                           [M + 2*V, N + 2*H]
%                       The default is [0 0], meaning no border.
%
%                       By default, the border is automatically removed
%                       from the result of FUN.  See the 'TrimBorder'
%                       parameter for more information.
%
%                       Blocks with borders that extend beyond the edges of
%                       the image are padded with zeros.
%
%   'TrimBorder'        A logical scalar.  When set to true, BLOCKPROC
%                       trims off border pixels from the output of the user
%                       function, FUN.  V rows are removed from the top and
%                       bottom of the output of FUN, and H columns are
%                       removed from the left and right edges, where V and
%                       H are defined by the 'BorderSize' parameter.  The
%                       default is true, meaning borders are automatically
%                       removed from the output of FUN.
%
%   'PadMethod'         The PadMethod determines how BLOCKPROC will pad the
%                       image boundary when necessary.  Options are:
%
%                         X             Pads the image with a scalar (X)
%                                       pad value.  By default X == 0.
%                         'replicate'   Repeats border elements of A.
%                         'symmetric'   Pads array with mirror reflections
%                                       of itself.
%
%   'PadPartialBlocks'  A logical scalar.  When set to true, BLOCKPROC will
%                       pad partial blocks to make them full-sized (M-by-N)
%                       blocks.  Partial blocks arise when the image size
%                       is not exactly divisible by the block size.  If
%                       they exist, partial blocks will lie along the right
%                       and bottom edge of the image.  The default is
%                       false, meaning the partial blocks are not padded,
%                       but processed as-is.
%
%                       BLOCKPROC uses zeros to pad partial blocks when
%                       necessary.
%
%   'UseParallel'       A logical scalar.  When set to true, BLOCKPROC will
%                       attempt to run in parallel mode, distributing the
%                       processing across multiple workers (MATLAB
%                       sessions) in an open MATLAB pool.  BLOCKPROC
%                       requires the Parallel Computing Toolbox to run in
%                       parallel mode.  When running in parallel mode, the
%                       input image cannot be an ImageAdapter object.  See
%                       the documentation for MATLABPOOL for information on
%                       configuring your parallel environment.
%
%   File Format Support
%   -------------------
%   Input and output files for BLOCKPROC (as specified by SRC_FILENAME
%   and/or the 'Destination' parameter) must be of the following file types
%   and must be named with one of the listed file extensions:
%
%       Read / Write File Formats
%       -------------------------
%       TIFF: *.tif, *.tiff
%       JPEG2000: *.jp2, *.j2c, *.j2k
%
%       Read-Only File Formats
%       ----------------------
%       JPEG2000: *.jpf, *.jpx
%
%   See the reference page for BLOCKPROC for additional file format
%   specific limitations.
%
%   Block Sizes
%   -----------
%   When using BLOCKPROC to either read or write image files, file access
%   can be an important factor in performance.  In general, selecting
%   larger block sizes will reduce the number of times BLOCKPROC will have
%   to access the disk, at the cost of using more memory to process each
%   block.  Knowledge of the file format layout on disk can also be useful
%   in selecting block sizes that minimize the number of times the disk is
%   accessed.
%
%   Examples
%   --------
%   This simple example uses the IMRESIZE function to generate an image
%   thumbnail.
%
%       fun = @(block_struct) imresize(block_struct.data,0.15);
%       I = imread('pears.png');
%       I2 = blockproc(I,[100 100],fun);
%       figure;
%       imshow(I);
%       figure;
%       imshow(I2);
%
%   This example uses BLOCKPROC to set the pixels in each 32-by-32 block
%   to the standard deviation of the elements in that block.
%
%       fun = @(block_struct) std2(block_struct.data) * ones(size(block_struct.data));
%       I2 = blockproc('moon.tif',[32 32],fun);
%       figure;
%       imshow('moon.tif');
%       figure;
%       imshow(I2,[]);
%
%   This example uses BLOCKPROC to switch the red and green bands of an RGB
%   image and writes the results to a new TIFF file.
%
%       I = imread('peppers.png');
%       fun = @(block_struct) block_struct.data(:,:,[2 1 3]);
%       blockproc(I,[200 200],fun,'Destination','grb_peppers.tif');
%       figure;
%       imshow('peppers.png');
%       figure;
%       imshow('grb_peppers.tif');
%
%   This example uses BLOCKPROC to convert a Tiff image into a new JPEG2000
%   image.
%
%       fun = @(block_struct) block_struct.data;
%       blockproc('largeImage.tif',[1024 1024],fun,'Destination','New.jp2');
%
%   See also COLFILT, FUNCTION_HANDLE, IMAGEADAPTER, NLFILTER.

%   Copyright 2008-2011 The MathWorks, Inc.
%   $Revision: 1.1.6.13.2.1 $  $Date: 2011/07/18 00:32:41 $
%
%   This is a heavily modified version of blockproc specifically for the
%   task of cropping ROIs from very large images. It should only be used
%   for this purpose and should only be used in conjunction with
%   LargeImageCropFcn.m.
%   Modifications written by Daniel Matthews, QBI Microscopy officer
%   (d.matthews1@uq.edu.au).
%   Last modified: 25/05/12

% parse all params and set appropriate defaults
[source,fun,options] = parse_inputs(source,block_size,fun,varargin{:});

% parse our 'Destination' parameter, check for file vs. adapter
if ~isempty(options.Destination)
    destination_specified = true;
    if isa(options.Destination,'char')
        dest_file_name = options.Destination;
    else
        dest_file_name = [];
    end
else
    destination_specified = false;
    dest_file_name = [];
end

% handle in-memory case with optimized private function
if (isnumeric(source) || islogical(source)) && ~destination_specified
    result_image = blockprocInMemory(source,fun,options);
    return
end

% check for incompatible parameters
if destination_specified && nargout > 0
    error(message('images:blockproc:tooManyOutputArguments'))
end

% create image adapter and onCleanup routine for non-adapter source images
source_file_name = [];
if ~isa(source,'ImageAdapter')
    % cache the source file name if input is indeed a file
    if ischar(source)
        source_file_name = source;
    end
    source = createInputAdapter(source);
    cleanup_source = onCleanup(@() source.close());
end
% create dispatcher for source adapter
source_dispatcher = internal.images.AdapterDispatcher(source,'r');

% compute size of required padding along image edges
row_padding = rem(source.ImageSize(1),options.BlockSize(1));
if row_padding > 0
    row_padding = options.BlockSize(1) - row_padding;
end
col_padding = rem(source.ImageSize(2),options.BlockSize(2));
if col_padding > 0
    col_padding = options.BlockSize(2) - col_padding;
end
options.Padding = [row_padding col_padding];

% total number of blocks we'll process (including partials)
mblocks = (source.ImageSize(1) + options.Padding(1)) / options.BlockSize(1);
nblocks = (source.ImageSize(2) + options.Padding(2)) / options.BlockSize(2);

% allocate/setup block struct
block_struct.border = options.BorderSize;
block_struct.blockSize = options.BlockSize;
block_struct.data = [];
block_struct.imageSize = source.ImageSize;
block_struct.location = [1 1];

% get first non-empty block and process it
rows_probed = false;
cols_probed = false;
[output_block ROIvec fun_nargout] = blockprocFunDispatcher(fun,block_struct,options.TrimBorder);
[rr,cc] = dangetRemainingBlockIndices(options.BlockSize,mblocks,nblocks,rows_probed,cols_probed,ROIvec);
row = rr(1);
col = cc(1);

block_struct = getBlock(source_dispatcher,block_struct,row,col,options);
[output_block ROIvec fun_nargout] = blockprocFunDispatcher(fun,block_struct,options.TrimBorder);

% verify user FUN either returned something valid or returned nothing
valid_output = isempty(output_block) || isnumeric(output_block) || ...
    islogical(output_block);
if ~valid_output
    error(message('images:blockproc:invalidOutputClass', class( output_block )));
end


% get output block size.  we explicitly get each dimension so that 2D
% blocks are reported in a 1x3 vector, eg [M x N x 1].
output_size = [size(output_block,1) size(output_block,2) size(output_block,3)];

%location of first non-empty block
first_row = rr(1);
first_col = cc(1);
first_output_size = output_size;

% create output image adapter if necessary and onCleanup routine
if destination_specified && isa(options.Destination,'ImageAdapter')
    % the Destination is an ImageAdapter, so we just wrap it with the dispatcher
    rows_probed = first_row;
    cols_probed = first_col;
    dest_dispatcher = internal.images.AdapterDispatcher(options.Destination,'r+');
    
    % copy the first block into the upper-left of the output matrix
    putBlock(dest_dispatcher,1,1,output_block,output_size);

else
    % we need to create the output adapter.  this also writes the first
    % upper-left block and probed blocks
    [dest,rows_probed,cols_probed] = createOutputAdapter(source,...
        block_struct,options,fun,mblocks,nblocks,output_size,output_block);
    options.Destination = dest;
    % cleanup Destination if necessary
    cleanup_dest = onCleanup(@() options.Destination.close());
end

% get row/column indices of all unprocessed blocks
[rr,cc,output_size_parallel,start_loc_parallel] = dangetRemainingBlockIndices...
                (options.BlockSize,mblocks,nblocks,rows_probed,cols_probed,ROIvec);
output_size_parallel(:,3) = 3;

% get number of remaining blocks
num_blocks = length(rr);
previously_processed = mblocks * nblocks - num_blocks;

% setup wait bar mechanics (must be declared at function scope)
wait_bar = [];
cleanup_waitbar = [];

% update wait bar for first 100 blocks and then per percentage increment
update_increments = unique([1:100 round((0.01:0.01:1) .* num_blocks)]);
update_counter = 1;

% inner loop starts
start_tic = tic;

if options.UseParallel
    % track progress of work for waitbar
    completed_blocks = false(1,numel(num_blocks));
    parallelLoop();
else
    danserialLoop();
end

% clean up wait bar if we made one
if ~isempty(wait_bar)
    clear cleanup_waitbar;
end

if ~destination_specified
    % return entire matrix when 'Destination' is not specified
    result_size = options.Destination.ImageSize;
    result_image = options.Destination.readRegion([1 1],result_size(1:2));
end


% Nested Functions
% ------------------------------------------------------------------------


    function parallelLoop()
        
        % Create copy of options struct with the 'Destination' adapter
        % removed for serialization
        clean_options = options;
        clean_options.Destination = [];
        
        try
            if ~isempty(source_file_name)
                parallel_function(...
                    [1 num_blocks],...
                    getFileProcessFcn(fun,fun_nargout,...
                    clean_options,source_file_name,rr,cc),...
                    @stitchFcn,...
                    [],[],[],[],[],...
                    Inf,@divideHarmonic);
            else
                parallel_function(...
                    [1 num_blocks],...
                    getMemoryProcessFcn(fun,fun_nargout,options.TrimBorder),...
                    @stitchFcn,...
                    @supplyFcn,[],[],[],[],...
                    Inf,@divideHarmonic);
                
            end
            
        catch ME
            % the cancel button generates this error as a signal
            if strcmp(ME.identifier,'images:blockprocInMemory:cancelParallelWaitbar')
                return
            else
                rethrow(ME);
            end
        end
        
        
        function stitchFcn(base,limit, outputBlocks)
            
            % Takes results from worker and writes to our output matrix
            destination = options.Destination;

            for blockInd = 1:(limit-base)
                
                % compute row/col of block
                k = base + blockInd;                
                
                row = rr(k);
                col = cc(k);
                completed_blocks(k) = true;
                
                out_size_curr = output_size_parallel(k,:);

                start_location = start_loc_parallel(k,:);

                % write to output
                %putBlock(options.Destination,row,col,outputBlocks{blockInd},output_size_para(blockInd,:));
                danputBlock(destination,start_location,outputBlocks{blockInd},out_size_curr);
            end
            
            updateWaitbar(sum(completed_blocks));
            
        end
        
        
        function inputBlocks = supplyFcn(base, limit)
            inputBlocks = cell(1,limit-base);
            for blockInd = 1:(limit-base)
                k = base + blockInd;
                row = rr(k);
                col = cc(k);
                
                inputBlocks{blockInd} = getBlock(source,block_struct,row,col,options);
            end
        end
        
        
    end % parallelLoop


    function danserialLoop
        
        out_size_old = first_output_size;
        destination = options.Destination;
        
        % process remaining blocks
        target_row_old = 1;
        target_col_old = 1;
        
        row_old = first_row;
        col_old = first_col;
                
        for k = 1 : num_blocks

            row_curr = rr(k);
            col_curr = cc(k);
            
            
            % read the next block to written
            block_struct = getBlock(source,block_struct,row_curr,col_curr,options);
            % process the block
            if fun_nargout > 0
                [output_block] = fun(block_struct);                
            else      
                fun(block_struct);
                output_block = [];
            end
            
            % if the row index hasn't changed we're in the same row so use
            % the old value of target row
            if (row_old - row_curr) == 0 
                target_row = target_row_old;          
            elseif row_curr == first_row || row_old == mblocks
                target_row = 1;
            else
                target_row = target_row_old + out_size_old(1);
            end


            % if the col index hasn't changed we're in the same col so use
            % the old value of target col
            if (col_old - col_curr) == 0 
                target_col = target_col_old;
            elseif col_curr == first_col || col_old == nblocks
                target_col = 1;
            else
                target_col = target_col_old + out_size_old(2);
            end
            
            if ~isempty(output_block)
                out_size_curr = [size(output_block,1) size(output_block,2) 1];
                start_location = [target_row target_col];
                danputBlock(destination,start_location,output_block,out_size_curr);
                out_size_old = out_size_curr;
            end

            
            % trim output if necessary
            if options.TrimBorder
                % get border size from options struct
                bdr = options.BorderSize;
                % trim the border
                output_block = output_block(bdr(1)+1:end-bdr(1),bdr(2)+1:end-bdr(2),:);
            end
            
            
            %update the prev values of output block size and row and column
            %values
            row_old = row_curr;
            col_old = col_curr;
            target_row_old = target_row;
            target_col_old = target_col;

            if updateWaitbar(k)
                break;
            end
            
        end
        
    end % serialLoop


    function abort = updateWaitbar(k)
        
        abort = false;
        
        % only update for specific values of k, updates are expensive
        if k >= update_increments(update_counter)
            
            update_counter = update_counter + 1;
            
            % keep a running total of how long we've taken
            elapsed_time = toc(start_tic);
            
            % display a wait bar if necessary
            if isempty(wait_bar)
                
                % decide if we need a wait bar or not
                remaining_time = elapsed_time / k * (num_blocks - k);
                if elapsed_time > 10 && remaining_time > 25
                    total_blocks = num_blocks;
                    if internal.images.isFigureAvailable()
                        wait_bar = iptui.cancellableWaitbar('Block Processing:',...
                            'Processing %d blocks',total_blocks,1 + k);
                        
                    else
                        wait_bar = iptui.textWaitUpdater('Block Processing %d blocks.',...
                            'Completed %d of %d blocks.',total_blocks);
                        
                    end
                    cleanup_waitbar = onCleanup(@() destroy(wait_bar)); %#ok<SETNU>
                end
                
            elseif wait_bar.isCancelled()
                % we had a waitbar, but the user hit the cancel button
                
                % clear onCleanup objects to close file handles
                clear cleanup_source cleanup_dest;
                
                % delete the output file if necessary
                if destination_specified && isequal(exist(dest_file_name,'file'),2)
                    delete(dest_file_name);
                end
                
                % reset output adapter to be empty (if nargout > 0)
                options.Destination = internal.images.MatrixAdapter([]);
                abort = true;
                
                if options.UseParallel
                    error(message('images:blockprocInMemory:cancelParallelWaitbar'));
                end
                
            else
                % we have a waitbar and it has not been canceled
                wait_bar.update(1 + k);
                drawnow;
                
            end
        end
        
    end % updateWaitbar

end % blockproc



%------------------------------------------------------------------------
function processFcn = getFileProcessFcn(fun,fun_nargout,options,...
    filename,rr,cc)

processFcn = @processBlocks;

    function outputBlocks = processBlocks(base,limit)
        
        source = createInputAdapter(filename);
        
        block_struct.border    = options.BorderSize;
        block_struct.blockSize = options.BlockSize;
        block_struct.imageSize = source.ImageSize;
        
        outputBlocks = cell(1,limit-base);
        
        for blockInd = 1:(limit-base)
            
            k = base + blockInd;
            
            row = rr(k);
            col = cc(k);
            
            block_struct = getBlock(source,block_struct,row,col,options);
            
            % process the block
            if fun_nargout > 0
                output_block = fun(block_struct);
            else
                fun(block_struct);
                output_block = [];
            end
            % trim output if necessary
            if options.TrimBorder
                % get border size from struct
                bdr = block_struct.border;
                % trim the border
                output_block = output_block(bdr(1)+1:end-bdr(1),bdr(2)+1:end-bdr(2),:);
            end
            
            outputBlocks{blockInd} = output_block;
            
        end
        
    end

end


%-------------------------------------------------------------------------
function processFcn = getMemoryProcessFcn(fun,fun_nargout,trim_border)

processFcn = @processBlocks;

    function outputBlocks = processBlocks(base,limit,inputBlocks)
        
        outputBlocks = cell(1,limit-base);
        
        for blockInd = 1:(limit-base)
            
            block_struct = inputBlocks{blockInd};
            
            %%% INLINED: blockprocFunDispatcher(fun,...) %%%
            % For performance we have inlined some code from blockprocFunDispatcher
            % in the inner loop.  Applicable changes made here should also be made
            % in the original sub-function.
            
            % process the block
            if fun_nargout > 0
                outputBlocks{blockInd} = fun(block_struct);
            else
                fun(block_struct);
                outputBlocks{blockInd} = [];
            end
            
            % trim output if necessary
            if trim_border
                % get border size from struct
                bdr = block_struct.border;
                % trim the border
                outputBlocks{blockInd} =...
                    outputBlocks{blockInd}...
                    (bdr(1)+1:end-bdr(1),bdr(2)+1:end-bdr(2),:);
            end
            
            %%% INLINE ENDING: blockprocFunDispatcher(fun,...) %%%
        end
    end
end


%------------------------------------------------------------------------
function [dest,rows_probed,cols_probed] = createOutputAdapter(source,...
    block_struct,options,fun,mblocks,nblocks,output_size,output_block)

dest = options.Destination;
output_class = class(output_block);

% return information about what blocks were processed
rows_probed = false;
cols_probed = false;

% compute the size of output image
num_full_block_rows = mblocks;
num_full_block_cols = nblocks;
num_extra_rows = 0;
num_extra_cols = 0;
if ~options.PadPartialBlocks
    % we're not padding, so compute the extra rows/cols along edges
    if options.Padding(1) > 0
        num_full_block_rows = num_full_block_rows - 1;
        num_extra_rows = options.BlockSize(1) - options.Padding(1);
    end
    if options.Padding(2) > 0
        num_full_block_cols = num_full_block_cols - 1;
        num_extra_cols = options.BlockSize(2) - options.Padding(2);
    end
end

% first compute the full-sized blocks' output size
output_rows = output_size(1) * num_full_block_rows;
output_cols = output_size(2) * num_full_block_cols;

if ~options.PadPartialBlocks
    % we probe the 2 extremities for excess edge output size
    if num_extra_rows > 0
        block_struct = getBlock(source,block_struct,mblocks,1,options);
        last_row_output = blockprocFunDispatcher(fun,block_struct,options.TrimBorder);
        output_rows = output_rows + size(last_row_output,1);
        rows_probed = true;
    end
    if num_extra_cols > 0
        block_struct = getBlock(source,block_struct,1,nblocks,options);...
            last_col_output = blockprocFunDispatcher(fun,block_struct,options.TrimBorder);
        output_cols = output_cols + size(last_col_output,2);
        cols_probed = true;
    end
end

% compute final image size
if output_size(3) > 1
    final_size = [output_rows output_cols output_size(3)];
else
    final_size = [output_rows output_cols];
end

% create ImageAdapter for output
outputClass = str2func(output_class);
if isempty(dest)
    % for matrix output
    dest_matrix = repmat(outputClass(0),final_size);
    dest = internal.images.MatrixAdapter(dest_matrix);
elseif ischar(dest)
    [~, ~, ext] = fileparts(dest);
    is_jpeg2000 = strcmpi(ext,'.jp2') || strcmpi(ext,'.j2c') || ...
        strcmpi(ext,'.j2k');
    % for file output
    if is_jpeg2000
        dest = internal.images.Jp2Adapter(dest,'w',final_size,outputClass(0));
    else
        dest = internal.images.TiffAdapter(dest,'w',final_size,outputClass(0));
    end
end

% create the dispatcher
dest_disp = internal.images.AdapterDispatcher(dest,'r+');

% Put the first output block, this is always probed
% For JPEG2000, the first block write must a top-left block
putBlock(dest_disp,1,1,output_block,output_size);

% if we had to probe for final image size, write out our probe results
if rows_probed
    putBlock(dest_disp,mblocks,1,last_row_output,output_size);
end
if cols_probed
    putBlock(dest_disp,1,nblocks,last_col_output,output_size);
end

end % createOutputAdapter


%-------------------------------------------------------------------
function block_struct = getBlock(source,block_struct,row,col,options)
% This function receives the block_struct as input to avoid reallocating every iteration
% We force the caller to specify the first argument because we want to pass
% in an adapter dispatcher in some cases, but directly pass in the image
% adapter object while inside the inner loop.

% compute starting row/col in source image of block of data
source_min_row = 1 + options.BlockSize(1) * (row - 1);
source_min_col = 1 + options.BlockSize(2) * (col - 1);
source_max_row = source_min_row + options.BlockSize(1) - 1;
source_max_col = source_min_col + options.BlockSize(2) - 1;
if ~options.PadPartialBlocks
    source_max_row = min(source_max_row,source.ImageSize(1));
    source_max_col = min(source_max_col,source.ImageSize(2));
end

% set block struct location (before border pixels are considered)
block_struct.location = [source_min_row source_min_col];

% add border pixels around the block of data
source_min_row = source_min_row - options.BorderSize(1);
source_max_row = source_max_row + options.BorderSize(1);
source_min_col = source_min_col - options.BorderSize(2);
source_max_col = source_max_col + options.BorderSize(2);

% setup indices for target block
total_rows = source_max_row - source_min_row + 1;
total_cols = source_max_col - source_min_col + 1;

% for interior blocks
if (source_min_row >= 1) && (source_max_row <= source.ImageSize(1)) && ...
        (source_min_col >= 1) && (source_max_col <= source.ImageSize(2))
    
    % no padding necessary, just read data and return
    block_struct.data = source.readRegion([source_min_row source_min_col],...
        [total_rows total_cols]);
    
elseif strcmpi(options.PadMethod,'constant')
    
    % setup target indices variables
    target_min_row = 1;
    target_max_row = total_rows;
    target_min_col = 1;
    target_max_col = total_cols;
    
    % check each edge of the requested block for edge
    if source_min_row < 1
        delta = 1 - source_min_row;
        source_min_row = source_min_row + delta;
        target_min_row = target_min_row + delta;
    end
    if source_max_row > source.ImageSize(1)
        delta = source_max_row - source.ImageSize(1);
        source_max_row = source_max_row - delta;
        target_max_row = target_max_row - delta;
    end
    if source_min_col < 1
        delta = 1 - source_min_col;
        source_min_col = source_min_col + delta;
        target_min_col = target_min_col + delta;
    end
    if source_max_col > source.ImageSize(2)
        delta = source_max_col - source.ImageSize(2);
        source_max_col = source_max_col - delta;
        target_max_col = target_max_col - delta;
    end
    
    % read source data
    source_data = source.readRegion(...
        [source_min_row                      source_min_col],...
        [source_max_row - source_min_row + 1 source_max_col - source_min_col + 1]);
    
    % allocate target block (this implicitly also handles constant value
    % padding around the edges of the partial blocks and boundary
    % blocks)
    inputClass = str2func(class(source_data));
    options.PadValue = inputClass(options.PadValue);
    block_struct.data = repmat(options.PadValue,[total_rows total_cols size(source_data,3)]);
    
    % copy valid data into target block
    target_rows = target_min_row:target_max_row;
    target_cols = target_min_col:target_max_col;
    block_struct.data(target_rows,target_cols,:) = source_data;
    
else
    
    % in this code path, have are guaranteed to require *some* padding,
    % either options.PadPartialBlocks, a border, or both.
    
    % Compute padding indices for entire input image
    has_border = ~isequal(options.BorderSize,[0 0]);
    if ~has_border
        % options.PadPartialBlocks only
        aIdx = getPaddingIndices(source.ImageSize(1:2),...
            options.Padding(1:2),options.PadMethod,'post');
        row_idx = aIdx{1};
        col_idx = aIdx{2};
        
    else
        % has a border...
        if  ~options.PadPartialBlocks
            % pad border only, around entire image
            aIdx = getPaddingIndices(source.ImageSize(1:2),...
                options.BorderSize,options.PadMethod,'both');
            row_idx = aIdx{1};
            col_idx = aIdx{2};
            
            
        else
            % both types of padding required
            aIdx_pre = getPaddingIndices(source.ImageSize(1:2),...
                options.BorderSize,options.PadMethod,'pre');
            post_padding = options.Padding(1:2) + options.BorderSize;
            aIdx_post = getPaddingIndices(source.ImageSize(1:2),...
                post_padding,options.PadMethod,'post');
            
            % concatenate the post padding onto the pre-padding results
            row_idx = [aIdx_pre{1} aIdx_post{1}(end-post_padding(1)+1:end)];
            col_idx = [aIdx_pre{2} aIdx_post{2}(end-post_padding(2)+1:end)];
            
        end
    end
    
    % offset the indices of our desired block to account for the
    % pre-padding in our padded index arrays
    source_min_row = source_min_row + options.BorderSize(1);
    source_max_row = source_max_row + options.BorderSize(1);
    source_min_col = source_min_col + options.BorderSize(2);
    source_max_col = source_max_col + options.BorderSize(2);
    
    % extract just the indices of our desired block
    block_row_ind = row_idx(source_min_row:source_max_row);
    block_col_ind = col_idx(source_min_col:source_max_col);
    
    % compute the absolute row/col limits containing all the necessary
    % data from our source image
    block_row_min = min(block_row_ind);
    block_row_max = max(block_row_ind);
    block_col_min = min(block_col_ind);
    block_col_max = max(block_col_ind);
    
    % read the block from the adapter object containing all necessary data
    source_data = source.readRegion(...
        [block_row_min                      block_col_min],...
        [block_row_max - block_row_min + 1  block_col_max - block_col_min + 1]);
    
    % offset our block_row/col_inds to align with the data read from the
    % adapter
    block_row_ind = block_row_ind - block_row_min + 1;
    block_col_ind = block_col_ind - block_col_min + 1;
    
    % finally index into our block of source data with the correctly
    % padding index lists
    block_struct.data = source_data(block_row_ind,block_col_ind,:);
    
end

data_size = [size(block_struct.data,1) size(block_struct.data,2)];
block_struct.blockSize = data_size - 2 * block_struct.border;

end % getBlock


%------------------------------------------------
function putBlock(dest,row,col,data,output_size)

% just bail on empty data
if isempty(data)
    return
end

if size(data,3) == 2
    data(:,:,3) = 0;
end

% compute destination location for target block
target_start_row = 1 + (row - 1) * output_size(1);
target_start_col = 1 + (col - 1) * output_size(2);

% we clip the output location based on the size of the destination data
max_row = target_start_row + output_size(1) - 1;
max_col = target_start_col + output_size(2) - 1;
excess = [0 0];
if max_row > dest.ImageSize(1)
    excess(1) = max_row - dest.ImageSize(1);
end
if max_col > dest.ImageSize(2)
    excess(2) = max_col - dest.ImageSize(2);
end

% account for blocks that are too large and go beyond the destination edge
output_size(1:2) = output_size(1:2) - excess;
% account for edge blocks that are not padded and are not full block sized
output_size(1:2) = min(output_size(1:2),[size(data,1) size(data,2)]);
% write valid block data to destination
start_loc = [target_start_row target_start_col];
dest.writeRegion(start_loc,...
    data(1:output_size(1),1:output_size(2),:));

end % putBlock

%------------------------------------------------
function danputBlock(dest,start_location,data,output_size)

% just bail on empty data
if isempty(data)
    return
end
size(data)
size(output_size)

if size(data,3) == 2
    data(:,:,3) = 0;
end

target_start_row = start_location(1);
target_start_col = start_location(2);

% we clip the output location based on the size of the destination data
max_row = target_start_row + output_size(1) - 1;
max_col = target_start_col + output_size(2) - 1;
excess = [0 0];
if max_row > dest.ImageSize(1)
    excess(1) = max_row - dest.ImageSize(1);
end
if max_col > dest.ImageSize(2)
    excess(2) = max_col - dest.ImageSize(2);
end
% 
% % account for blocks that are too large and go beyond the destination edge
output_size(1:2) = output_size(1:2) - excess;
% % account for edge blocks that are not padded and are not full block sized
output_size(1:2) = min(output_size(1:2),[size(data,1) size(data,2)]);

% write valid block data to destination
start_loc = start_location;
dest.writeRegion(start_loc,...
    data(1:output_size(1),1:output_size(2),:));
% dest.writeRegion(start_loc,data);

end % danputBlock


%----------------------------------------------
function adpt = createInputAdapter(data_source)
% data_source has been previously validated during input parsing.  It is
% either a string filename with a valid TIFF or JPEG2000 extension, or else
% it's a numeric or logical matrix.

if ischar(data_source)
    
    % data_source is a file.  We verified in the parse_inputs function that
    % it is a TIFF or Jpeg2000 file with a valid extension.
    [~, ~, ext] = fileparts(data_source);
    is_tiff = strcmpi(ext,'.tif') || strcmpi(ext,'.tiff');
    is_jp2 = strcmpi(ext,'.jp2') || strcmpi(ext,'.jpf') || ...
        strcmpi(ext,'.jpx') || strcmpi(ext,'.j2c') || ...
        strcmpi(ext,'.j2k');
    if is_tiff
        adpt = internal.images.TiffAdapter(data_source,'r');
    elseif is_jp2
        adpt = internal.images.Jp2Adapter(data_source,'r');
    else
        % unknown format, try imread adapter
        adpt = internal.images.ImreadAdapter(data_source);
    end
    
else
    % otherwise it's numeric or logical, verified during input parsing.
    % This code path is hit when the input is in memory and a 'Destination'
    % is specified or when the input is a file/adapter.
    adpt = internal.images.MatrixAdapter(data_source);
end

end % createInputAdapter

%-------------------------------------------------------------------------
function [rr,cc,outsize,start_location] = dangetRemainingBlockIndices(block_size,mblocks,nblocks,rows_probed,cols_probed,ROIvec)

numBlocks = mblocks * nblocks;

AllBlksStart = zeros(numBlocks,2);
BlkStartRow = 1:mblocks;
BlkStartCol = 1:nblocks;
AllBlksStart(:,1) = repmat(BlkStartRow',[nblocks 1]);
AllBlksStartCol = repmat(BlkStartCol,[mblocks 1]);
AllBlksStart(:,2) = reshape(AllBlksStartCol,numBlocks,1);
%find the row col indices of those blocks that overlap with the ROI
%vector
StartInBlock = [1 1];
EndInBlock = [1 1];
 %location
% Set up the region of interest to crop
BoundingBoxStart = floor(ROIvec(1:2));
BoundingBoxEnd(1) = BoundingBoxStart(1) + floor(ROIvec(3));
BoundingBoxEnd(2) = BoundingBoxStart(2) + floor(ROIvec(4));
% Find out the start and end positions of the Bounding Box relative to the block
% start positions
location = zeros(numBlocks,2);
for iBlock = 1 : numBlocks
    location(iBlock,1) = (AllBlksStart(iBlock,1) - 1)*block_size(1) + 1;
    location(iBlock,2) = (AllBlksStart(iBlock,2) - 1)*block_size(2) + 1;


    if BoundingBoxStart(1) == location(iBlock,1)
        StartInBlock(iBlock,1) = 1;
    else
        StartInBlock(iBlock,1) = BoundingBoxStart(1) - location(iBlock,1) + 1;
    end

    if BoundingBoxStart(2) == location(iBlock,2)
        StartInBlock(iBlock,2) = 1;
    else
        StartInBlock(iBlock,2) = BoundingBoxStart(2) - location(iBlock,2) + 1;
    end

    EndInBlock(iBlock,1) = BoundingBoxEnd(1) - location(iBlock,1) + 1;
    EndInBlock(iBlock,2) = BoundingBoxEnd(2) - location(iBlock,2) + 1;

    % Now find out if the Bounding Box overlaps with the current block
    % check if the start in block value from above is -ve and see if
    % the absolute value of the ROI.
    % If the start points are +ve and less than the block size then the
    % start point must lie within the block so keep the values. If the
    % start point is -ve then the start point relative to the block must be
    % on the block boundary so make this value 1

    if StartInBlock(iBlock,1) < 0
        %check the absolute value and see if it is greater than the
        %size of the bounding box
        if abs(StartInBlock(iBlock,1)) > ROIvec(3) 
            StartInBlock(iBlock,1) = NaN;
        else
            StartInBlock(iBlock,1) = 1;
        end
    end

    if StartInBlock(iBlock,2) < 0
        if abs(StartInBlock(iBlock,2)) > ROIvec(4)
            StartInBlock(iBlock,2) = NaN;
        else
            StartInBlock(iBlock,2) = 1;
        end
    end

    if StartInBlock(iBlock,1) > block_size(1)
        %check the absolute value and see if it is greater than the
        %size of the bounding box
        if StartInBlock(iBlock,1) > ROIvec(3)
            StartInBlock(iBlock,1) = NaN;
        end                
    end

    if StartInBlock(iBlock,2) > block_size(2)
        if StartInBlock(iBlock,2) > ROIvec(4)
            StartInBlock(iBlock,2) = NaN;
        end
    end
end

StartPoint = StartInBlock;    

EndPoint = EndInBlock;

%if the end point is greater than the block size (i.e. the end point
%lies outside the block) then subtract the size of the bounding box
SizeInBlk = zeros(numBlocks,2);
for iBlock = 1:numBlocks
    if abs(EndPoint(iBlock,1)) > block_size(1)
        if abs(EndPoint(iBlock,1)) > BoundingBoxEnd(1)
            SizeInBlk(iBlock,1) = 1;
        else
            SizeInBlk(iBlock,1) = block_size(1) - StartPoint(iBlock,1) + 1;
        end
    else
        SizeInBlk(iBlock,1) = EndPoint(iBlock,1);
    end

    if abs(EndPoint(iBlock,2)) > block_size(2)        
        if abs(EndPoint(iBlock,2)) > BoundingBoxEnd(2)
            SizeInBlk(iBlock,2) = 1;
        else
            SizeInBlk(iBlock,2) = block_size(2) - StartPoint(iBlock,2) + 1;
        end
    else
        SizeInBlk(iBlock,2) = EndPoint(iBlock,2);
    end

    if ROIvec(3) < block_size(1) && ROIvec(4) < block_size(2)
        if ROIvec(1) - location(iBlock,1) > block_size(1) ||...
                ROIvec(2) - location(iBlock,2) > block_size(2)
            SizeInBlk(iBlock,1) = NaN;
            SizeInBlk(iBlock,2) = NaN;
        else
            SizeInBlk(iBlock,1) = ROIvec(3);
            SizeInBlk(iBlock,2) = ROIvec(4);
        end
    end

    if SizeInBlk(iBlock,1) <= 0 
        SizeInBlk(iBlock,1) = NaN;
    end

    if SizeInBlk(iBlock,2) <= 0
        SizeInBlk(iBlock,2) = NaN;
    end

    if abs(SizeInBlk(iBlock,1)) == 1
        SizeInBlk(iBlock,1) = NaN;
    end

    if abs(SizeInBlk(iBlock,2)) == 1
        SizeInBlk(iBlock,2) = NaN;
    end
end

blk2keep = ~isnan(SizeInBlk);
blkidx = find(blk2keep(:,1) & blk2keep(:,2));
AllBlksStart = AllBlksStart(blkidx,:);
SizeInBlk = SizeInBlk(blkidx,:);

rr = AllBlksStart(:,1);
cc = AllBlksStart(:,2);
outsize = SizeInBlk;

out_size_old = outsize(1,:);

% process remaining blocks
target_row_old = 1;
target_col_old = 1;

row_old = rr(1);
col_old = cc(1);
first_row = rr(1);
first_col = cc(1);
start_location = zeros(length(blkidx) - 1,2);
for k = 2 : length(blkidx)

    row_curr = rr(k);
    col_curr = cc(k);

    % if the row index hasn't changed we're in the same row so use
    % the old value of target row
    if (row_old - row_curr) == 0 
        target_row = target_row_old;          
    elseif row_curr == first_row || row_old == mblocks
        target_row = 1;
    else
        target_row = target_row_old + out_size_old(1);
    end


    % if the col index hasn't changed we're in the same col so use
    % the old value of target col
    if (col_old - col_curr) == 0 
        target_col = target_col_old;
    elseif col_curr == first_col || col_old == nblocks
        target_col = 1;
    else
        target_col = target_col_old + out_size_old(2);
    end

    out_size_curr = outsize(k,:);
    start_location(k - 1,1) = target_row; 
    start_location(k - 1,2) = target_col;

    %update the prev values of output block size and row and column
    %values
    row_old = row_curr;
    col_old = col_curr;
    target_row_old = target_row;
    target_col_old = target_col;
    out_size_old = out_size_curr;
end

if rows_probed && cols_probed
    % if the image has been probed get rid of rows and cols of those probed
    AllBlksStart(1,:) = [];
    SizeInBlk(1,:) = [];
    rr = AllBlksStart(:,1);
    cc = AllBlksStart(:,2);
    outsize = cell(length(rr),length(cc));
    outsize = SizeInBlk;
end

end % getRemainingBlockIndices


%-------------------------------------------------------------------------
function [rr,cc] = getRemainingBlockIndices(mblocks,nblocks,rows_probed,cols_probed)

% get row/column indices of all unprocessed blocks
% start with interior blocks (guaranteed unprobed rows/cols)
[r,c] = meshgrid(2:mblocks,2:nblocks);
rr = r(:);
cc = c(:);

% add unprocessed blocks from first row
if cols_probed
    end_col = nblocks - 1;
else
    end_col = nblocks;
end
[r,c] = meshgrid(1,2:end_col);
rr = [r(:);rr];
cc = [c(:);cc];

% add unprocessed blocks from first column
if rows_probed
    end_row = mblocks - 1;
else
    end_row = mblocks;
end
[r,c] = meshgrid(2:end_row,1);
rr = [r(:);rr];
cc = [c(:);cc];

end % getRemainingBlockIndices

%-------------------------------------------------------------------------
function [source,fun,options] = parse_inputs(source,block_size,fun,varargin)
% Parse blockproc syntax

% create options struct with all defaults
options = getDefaultOptions;

% validate Source Image
valid_matrix = isnumeric(source) || islogical(source);
valid_file = ischar(source) && isequal(exist(source,'file'),2);
valid_adapter = isa(source,'ImageAdapter');
% validate file
if valid_file
    [~, ~, ext] = fileparts(source);
    is_readWrite = strcmpi(ext,'.tif') || strcmpi(ext,'.tiff') || ...
        strcmpi(ext,'.j2k') || strcmpi(ext,'.j2c') || ...
        strcmpi(ext,'.jp2');
    is_readOnly = strcmpi(ext,'.jpf') || strcmpi(ext,'.jpx');
    if is_readWrite || is_readOnly
        valid_file = true;
    else
        valid_file = false;
    end
end

% validate image size for matrix input
if valid_matrix && numel(size(source)) > 3
    error(message('images:blockproc:invalidImageSize'))
end

if ~(valid_matrix || valid_file || valid_adapter)
    error(message('images:blockproc:invalidInputImage'))
end

% validate block_size
floored_block_size = floor(block_size);
correct_size = isequal(size(floored_block_size),[1 2]);
non_negative = all(floored_block_size > 0);
non_inf = ~any(isinf(floored_block_size));
if ~(isnumeric(floored_block_size) && correct_size && non_negative && non_inf)
    error(message('images:blockproc:invalidBlockSize'))
end

% warn for non integer block_sizes
if ~all(block_size == floored_block_size)
    warning(message('images:blockproc:fractionalBlockSize', 'BLOCKPROC did not expect a fractional ''BlockSize'' ', 'parameter.  It will be truncated before use.'));
end

options.BlockSize = floored_block_size;

% validate user provided function handle
if ~isa(fun,'function_handle')
    error(message('images:blockproc:invalidFunction'))
end

% handle remaining P/V pairs
num_varargin = numel(varargin);
if (rem(num_varargin, 2) ~= 0)
    error(message('images:blockproc:paramMissingValue'))
end

% Create a structure with default values, and map actual param-value pair
% names to convenient names for internal use.
ParamName = {'BorderSize','Destination','PadMethod',...
    'PadPartialBlocks','TrimBorder','UseParallel'};
ValidateFcn = {@checkBorderSize, @checkDestination, @checkPadMethod,...
    @checkPadPartialBlocks, @checkTrimBorder, @checkUseParallel};

% Loop over the P/V pairs.
for p = 1:2:num_varargin
    
    % Get the parameter name.
    user_param = varargin{p};
    if (~ischar(user_param))
        error(message('images:blockproc:badParamName'))
    end
    
    % Look for the parameter amongst the possible values.
    logical_idx = strncmpi(user_param, ParamName, numel(user_param));
    
    if ~any(logical_idx)
        error(message('images:blockproc:unknownParamName', user_param));
    elseif numel(find(logical_idx)) > 1
        error(message('images:blockproc:ambiguousParamName', user_param));
    end
    
    % Validate the value.
    validateFcn = ValidateFcn{logical_idx};
    param_value = varargin{p+1};
    options.(ParamName{logical_idx}) = validateFcn(param_value);
end

% separate PadMethod into the actual method and value
if isscalar(options.PadMethod)
    options.PadValue = options.PadMethod;
    options.PadMethod = 'constant';
end

% never attempt to trim a [0 0] border
if isequal(options.BorderSize,[0 0])
    options.TrimBorder = false;
end

% further validation of the parallel option
% if options.UseParallel && valid_adapter
%     warning(message('images:blockproc:invalidParallelSource'));
%     options.UseParallel = false;
% end

% save number of workers in our pool
if options.UseParallel
    options.NumWorkers = matlabpool('size');
end

% verify the input file is available to worker MATLABs
if options.UseParallel && valid_file
    
    spmd (options.NumWorkers)
        
        fid = fopen(source,'r');
        file_is_available = (fid ~= -1);
        if file_is_available
            fclose(fid);
        end
        
    end
    
    if  ~all([file_is_available{:}])
        error(message('images:blockproc:FileNotAvailableToParallelWorkers'));
    end
    
end

end % parse_inputs


%-----------------------------------
function options = getDefaultOptions

% set default options
options.BlockSize = [0 0];
options.BorderSize = [0 0];
options.Destination = [];
options.PadPartialBlocks = false;
options.PadMethod = 'constant';
options.PadValue = 0;
options.Padding = [0 0];
options.TrimBorder = true;
options.UseParallel = false;
options.NumWorkers = 0;

end % getDefaultOptions


%-----------------------------------------
function output = checkDestination(output)

valid_file = ischar(output);
valid_adapter = isa(output,'ImageAdapter');

if valid_file
    [~, ~, ext] = fileparts(output);
    is_readWrite = strcmpi(ext,'.tif') || strcmpi(ext,'.tiff') || ...
        strcmpi(ext,'.j2k') || strcmpi(ext,'.j2c') || ...
        strcmpi(ext,'.jp2');
    if ~is_readWrite
        valid_file = false;
    end
end

if ~(valid_file || valid_adapter)
    error(message('images:blockproc:invalidDestination'))
end
end


%--------------------------------------------------
function border_size = checkBorderSize(border_size)
correct_size = isequal(size(border_size),[1 2]);
non_negative = all(border_size >= 0);
non_inf = ~any(isinf(border_size));
if ~(isnumeric(border_size) && correct_size && non_negative && non_inf)
    error(message('images:blockproc:invalidBorderSize'))
end

% warn for non integer block_sizes
if ~all(border_size == floor(border_size))
    warning(message('images:blockproc:fractionalBorderSize'))
end

border_size = floor(border_size);

end


%-----------------------------------------------
function pad_method = checkPadMethod(pad_method)

valid_scalar = false;
valid_method = false;
if isscalar(pad_method) && (isnumeric(pad_method) || islogical(pad_method))
    valid_scalar = true;
elseif ischar(pad_method) && ...
        (strcmpi(pad_method,'replicate') || strcmpi(pad_method,'symmetric'))
    valid_method = true;
end

if ~valid_scalar && ~valid_method
    error(message('images:blockproc:invalidPadMethodParam'))
end
end


%----------------------------------------------------------------------
function pad_partial_blocks = checkPadPartialBlocks(pad_partial_blocks)
if ~(islogical(pad_partial_blocks) || isnumeric(pad_partial_blocks))
    error(message('images:blockproc:invalidPadPartialBlocksParam'))
end
end


%--------------------------------------------------
function trim_border = checkTrimBorder(trim_border)
if ~(islogical(trim_border) || isnumeric(trim_border))
    error(message('images:blockproc:invalidTrimBorderParam'))
end
end


%-----------------------------------------------------
function use_parallel = checkUseParallel(use_parallel)

if ~(islogical(use_parallel) || isnumeric(use_parallel))
    error(message('images:blockproc:invalidUseParallelParam'))
end

% verify pct is installed
if use_parallel && ~pctInstalled()
    use_parallel = false;
end

% verify matlabpool is open
if use_parallel && matlabpool('size') < 1
    use_parallel = false;
end
end


%---------------------------
function tf = pctInstalled()
% uses same logic as that found in parallel_function

persistent PCT_INSTALLED

if isempty(PCT_INSTALLED)
    % See if we have the correct code to try this
    PCT_INSTALLED = logical(exist('com.mathworks.toolbox.distcomp.pmode.SessionFactory', 'class')) && ...
        exist('distcompserialize', 'file') == 3; % 3 == MEX
end
tf = PCT_INSTALLED;
end

