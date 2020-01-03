% test 2.0 ari correction

% parameters to use in prmflow
Npixel = prmflow.recon.Npixel;
Nslice = prmflow.recon.Nslice;
Nview = prmflow.recon.Nview;
Nfocal = prmflow.system.Nfocal;

% calibration table
aircorr = prmflow.corrtable.Air;
% parameters in corr
Nsect = single(aircorr.Nsection);
refpixel = single(aircorr.refpixel);
Nref = aircorr.refnumber;

% angles of the air table
sectangle = (pi*2/Nsect);
% airangle = (-1:Nsect).*(pi*2/Nsect);
% airmain & airref
aircorr.main = reshape(aircorr.main, [], Nsect);
airmain = [aircorr.main aircorr.main(:,1)];
aircorr.reference = reshape(aircorr.reference, [], Nsect);
airref = [aircorr.reference aircorr.reference(:,1)];

% interp index and weight
retangle = mod(dataflow.rawhead.viewangle - aircorr.firstangle, pi*2);
intp_index = floor(retangle./sectangle);
intp_alpha = retangle./sectangle - intp_index;
intp_index = intp_index + 1;

% reshape
dataflow.rawdata = reshape(dataflow.rawdata, Npixel*Nslice, Nview);

% corr rawdata with air
for ifocal = 1:Nfocal
    viewindex = ifocal:Nfocal:Nview;
    airindex = (1:Npixel*Nslice) + Npixel*Nslice*(ifocal-1);
    dataflow.rawdata(:, viewindex) = dataflow.rawdata(:, viewindex) - airmain(airindex, intp_index).*(1-intp_alpha(viewindex));
    dataflow.rawdata(:, viewindex) = dataflow.rawdata(:, viewindex) - airmain(airindex, intp_index+1).*intp_alpha(viewindex);
end

% skip the edge slices
if Nslice>2
    index_slice = 2:Nslice-1;
    Nrefsl = Nslice-2;
else
    index_slice = 1:Nslice;
    Nrefsl = Nslice;
end

dataflow.rawdata = reshape(dataflow.rawdata, Npixel, Nslice, []);

% referenece data
ref1_d = reshape(dataflow.rawdata(1:refpixel, index_slice, :), [], Nview);
ref2_d = reshape(dataflow.rawdata(Npixel-refpixel+1:Npixel, index_slice, :), [], Nview);

% reference error

% SVD 
ref1_err = reshape(ref1_d-mean(ref1_d, 1), Nrefsl, refpixel, Nview);
ref2_err = reshape(ref2_d-mean(ref2_d, 1), Nrefsl, refpixel, Nview);
refsvd = zeros(2, Nview);
refstd = zeros(2, Nview);
refLinf = zeros(2, Nview);
for iview = 1:Nview
    % SVD
    s1 = svd(ref1_err(:, :, iview));
    refsvd(1, iview) = s1(1);
    s2 = svd(ref2_err(:, :, iview));
    refsvd(2, iview) = s2(1);
    % STD 
    refstd(1, iview) = std(reshape(ref1_err(:, :, iview),1,[]));
    refstd(2, iview) = std(reshape(ref2_err(:, :, iview),1,[]));
    % L_inf
    refLinf(1, iview) = max(abs(reshape(ref1_err(:, :, iview),1,[])));
    refLinf(2, iview) = max(abs(reshape(ref2_err(:, :, iview),1,[])));
end
% norm
refsvd = refsvd./sqrt(Nrefsl*refpixel);
refstd = refstd./sqrt(Nrefsl*refpixel);

% select one
referr = refsvd;

% STD error
% referr = [sqrt(sum((ref1_d-mean(ref1_d, 1)).^2)); sqrt(sum((ref2_d-mean(ref2_d, 1)).^2))];
% referr = referr./sqrt(Nrefsl*refpixel);


% rawref
ref1 = mean(ref1_d, 1);
ref2 = mean(ref2_d, 1);
% rawref = [ref1; ref2];

% ref block
block_cut = 4.0e-4;
m_blk = 10;
blk1 = conv(referr(1,:)>block_cut, ones(1, 2*m_blk+1));
blk2 = conv(referr(2,:)>block_cut, ones(1, 2*m_blk+1));
blk1 = blk1(m_blk+1:end-m_blk)>0;
blk2 = blk2(m_blk+1:end-m_blk)>0;

idx_both = ~blk1 & ~blk2;

ref = zeros(1, Nview);
ref(idx_both) = (ref1(idx_both) + ref2(idx_both))./2;

if any(~idx_both)
    % some views are blocked
    blkidx_1 = ~blk1 & blk2;
    blkidx_2 = blk1 & ~blk2;
    % 
    view_bkl1 = find(~idx_both, 1, 'first');
    view0 = find(idx_both, 1, 'first');
    if view_bkl1==1
        %1 go back
        for ii = view0-1:-1:1
            if blkidx_1(ii)
                % ref1
                ref(ii) = ref(ii+1)-ref1(ii+1)+ref1(ii);
            elseif blkidx_2(ii)
                % ref2
                ref(ii) = ref(ii+1)-ref2(ii+1)+ref2(ii);
            else
                % mA
                1;
            end
        end
        %2 forward
        view_bkl1 = find(~idx_both(view0:end), 1, 'first');
    end
    for ii = view_bkl1:Nview
        if idx_both(ii)
            continue
        end
        if blkidx_1(ii)
            % ref1
            ref(ii) = ref(ii-1)-ref1(ii-1)+ref1(ii);
        elseif blkidx_2(ii)
            % ref2
            ref(ii) = ref(ii-1)-ref2(ii-1)+ref2(ii);
        else
            % mA
            1;
        end
        
        
    end
     
end

