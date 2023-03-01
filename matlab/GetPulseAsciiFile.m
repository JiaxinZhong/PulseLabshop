% =========================================================================
% VERSION INFO
%	Last modified	---	2020-06-26
%	Version no.		--- 2.2
% -------------------------------------------------------------------------
% DEPENDENCIES
%	No.
% -------------------------------------------------------------------------
% FUNCTION
%   - This function read the output ASCII file of PULSE Labshop.
%   - This function can also be used to read the output ASCII file
%   	from "Bridge to Matlab" application of PULSE LabShop. If this is 
%		the	case, you may run the code called 'BKFiles.m' created by 
%		Pulse LabShop.
% -------------------------------------------------------------------------
% OUTPUT
%   - The output data are a struct cell, which have the fields 'data', 
%		'freq', 'prs', 'spl'.
%	- Each field is nn a cell array in a column corresponding to the 
%		channel in PULSE LabShop.
% =========================================================================
function data = GetPulseAsciiFile(filename)  

    % determine the input argument type
    if iscell(filename)
        data = cell(size(filename));
        for i = 1:length(filename)
            data{i} = GetPulseAsciiFile_Primitive(filename{i});
        end
    else
        data = GetPulseAsciiFile_Primitive(filename);
    end
            
    
end    
    
function data = GetPulseAsciiFile_Primitive(filename)  

    warning('off','MATLAB:dispatcher:InexactMatch');

    % preallocating memory
    data_buf = [];
    stop = [];
    cnt = 0;

    % Read the file
    fid = fopen(filename);
    while isempty(stop) % repeat the read header
        tline = fgetl(fid);
        if tline == -feof(fid) %eof
            break
        end
        % Read header
        while isempty(stop)
            tline = fgetl(fid);
            if tline == -feof(fid) %eof
                break
            end
            stop = str2num(tline); %stops when it finds a number
        end        
        % Read data
        theData = [];
        cnt = cnt + 1;
        while ~isempty(stop)
            linedata = sscanf(tline,'%f')'; %read row of data
            theData = [theData; linedata]; %collect data
            data_buf{cnt,1} = theData;  %assign data to cell
            tline = fgetl(fid);
            stop = str2num(tline); %stops when it finds a char
        end
    end
    fclose(fid);

    %% the total numer of data
    nData = size(data_buf, 1);

    %% Process the results
    freq = cell(nData, 1);
    prsReal = cell(nData, 1);
    prsImag = cell(nData, 1);
    prsPhase = cell(nData, 1);
    prsMagnitude = cell(nData, 1);
    spl = cell(nData, 1);
     
    for iData = 1:nData
        % the 1st column of the data is ordinary number
        % the 2nd column of the data is frequency
        freq{iData} = data_buf{iData}(:,2);
    end

    nColumns = size(data_buf{nData}, 2);

    switch nColumns
        % often referring to: 
        %	FFT Analyzer - Autospectrum
        case 3
            % the 3rd column of the data is autospectrum
            for iData = 1:nData
                % calculate the magnitude
                prsMagnitude{iData} = sqrt(2)*sqrt(data_buf{iData}(:,3));
                % calculate the dB value
                spl{iData} = 20 * log10(prsMagnitude{iData}/...
                sqrt(2)/(20e-6));
            
                prsReal{iData} = prsMagnitude{iData};
                prsImag{iData} = prsReal{iData} * 0;
            end
            
        % referring to:
        %	FFT Analyzer - Frequency Response H1
        %	SSR Analyzer - Output Response
        case 4
            for iData = 1:nData
                % Store the real and imaginary parts
                prsReal{iData} = data_buf{iData}(:,3);
                prsImag{iData} = data_buf{iData}(:,4);
                prsPhase{iData} = angle(prsReal{iData} + 1i * prsImag{iData});

                % calculate the magnitude
                prsMagnitude{iData} = sqrt(prsReal{iData}.^2 + prsImag{iData}.^2);

                % Calculate the dB value
                spl{iData} = 20 * log10(prsMagnitude{iData}/sqrt(2)/(20e-6));
            end
            
        otherwise
    end

    %% allocate the output data
    % contains all the data read from the pulse file
    data.data = data_buf;		
    % the frequency 
    data.freq = freq;
    % the total number of the data block contains in the pulse file
    data.nData = nData;
    data.prs = prsReal;
    for i = 1:length(prsReal)
        data.prs{i} = data.prs{i} + 1i *prsImag{i};
    end
    % the level in dB of the prs 
    data.spl = spl;

    if nData == 1
        data.data = data.data{1};
        data.freq = data.freq{1};
        data.prs = data.prs{1};
        data.spl = data.spl{1};
    end
end
