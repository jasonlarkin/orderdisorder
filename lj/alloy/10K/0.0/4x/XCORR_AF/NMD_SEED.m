
NMD=load('./NMD.mat');

[tmp,str.main]=system('pwd');

%freq    
    SED.HLDfreq(1:NMD.NUM_MODES) = NMD.freq(1:NMD.NUM_MODES);
%modes
    SED.modemaster = NMD.modemaster;
%Input SED
    SED.sed( 1:NMD.NUM_TSTEPS,1:NMD.NUM_MODES ) = 0.0;

for imode = 1:NMD.NUM_MODES
%--------------------------------------------------------------------------
tic
%--------------------------------------------------------------------------
        str.read=...
            strcat(NMD.str.main,'/',int2str(NMD.seed.alloy),'/work/NMD/SED_',...
                num2str(NMD.modemaster(imode)),'.txt');
        dummy = load(str.read); 
        %sed
        SED.sed(1:NMD.NUM_TSTEPS,imode) = dummy(:,2);
        %omega
        SED.omega = dummy(:,1);
%--------------------------------------------------------------------------
toc
%--------------------------------------------------------------------------
end

save(...
    strcat(...
    NMD.str.main,'/',int2str(NMD.seed.alloy),'/NMDavg.mat'), '-struct', 'NMD');
save(...
    strcat(...
    NMD.str.main,'/',int2str(NMD.seed.alloy),'/SEDavg.mat'), '-struct', 'SED');


