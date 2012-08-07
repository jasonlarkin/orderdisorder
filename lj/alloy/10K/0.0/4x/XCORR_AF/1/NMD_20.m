 
NMD=load('./NMD.mat');

[tmp,str.main]=system('pwd');

%---IKSLICE----------------------------------------------------------------
    imslice = 20;
%-------------------------------------------------------------------------- 

SED.SED(...
    size(NMD.kptmaster(:,1:3),1),...
    1:(NMD.NUM_TSTEPS),1:size(NMD.modelist(:,imslice),1)) = 0.0;

for iseed = 1:NMD.NUM_SEEDS
    
for ifft = 1:NMD.NUM_FFTS  
%VElOCITIES
    str_read=...
        strcat(...
        str.main ,'/dump_',int2str(iseed),'_',int2str(ifft),'.vel');
    fid=fopen(str_read);
    dummy = textscan(fid,'%f%f%f','Delimiter',' ','commentStyle', '--'); 
    fclose(fid);
%POSITIONS
    str_read=...
        strcat(...
        str.main ,'/dump_',int2str(iseed),'_',int2str(ifft),'.pos');
    fid=fopen(str_read);
    dummy2 = textscan(fid,'%f%f%f','Delimiter',' ','commentStyle', '--'); 
    fclose(fid);
%Store velocity data of all atoms: subtract off the last time step
    velx = zeros(NMD.NUM_ATOMS,NMD.NUM_TSTEPS);
    vely = zeros(NMD.NUM_ATOMS,NMD.NUM_TSTEPS);
    velz = zeros(NMD.NUM_ATOMS,NMD.NUM_TSTEPS);

    posx = zeros(NMD.NUM_ATOMS,NMD.NUM_TSTEPS);
    posy = zeros(NMD.NUM_ATOMS,NMD.NUM_TSTEPS);
    posz = zeros(NMD.NUM_ATOMS,NMD.NUM_TSTEPS);

%--------------------------------------------------------------------------
tic  
%--------------------------------------------------------------------------
    for iatom = 1:NMD.NUM_ATOMS  
        velx(iatom,1:NMD.NUM_TSTEPS) =...
            dummy{1}...
            (iatom:NMD.NUM_ATOMS:(length(dummy{1}(:))-NMD.NUM_ATOMS));
        vely(iatom,1:NMD.NUM_TSTEPS) =...
            dummy{2}...
            (iatom:NMD.NUM_ATOMS:(length(dummy{1}(:))-NMD.NUM_ATOMS));
        velz(iatom,1:NMD.NUM_TSTEPS) =...
            dummy{3}...
            (iatom:NMD.NUM_ATOMS:(length(dummy{1}(:))-NMD.NUM_ATOMS));

    	posx(iatom,1:NMD.NUM_TSTEPS) =...
	    dummy2{1}(iatom:NMD.NUM_ATOMS:(length(dummy2{1}(:))-NMD.NUM_ATOMS))- ...
		NMD.x0(iatom,3);
    	posy(iatom,1:NMD.NUM_TSTEPS) =...
	    dummy2{2}(iatom:NMD.NUM_ATOMS:(length(dummy2{1}(:))-NMD.NUM_ATOMS))- ...
		NMD.x0(iatom,4);
    	posz(iatom,1:NMD.NUM_TSTEPS) =...
	    dummy2{3}(iatom:NMD.NUM_ATOMS:(length(dummy2{1}(:))-NMD.NUM_ATOMS))-...
		NMD.x0(iatom,5);
    end
%--------------------------------------------------------------------------
toc
%--------------------------------------------------------------------------
%Remove dummy
    clear dummy dummy2
%Set mass array
%     m = repmat(NMD.mass(:,1),1,NMD.NUM_TSTEPS);     
    m = NMD.mass(:,1);
%EIGENVECTORS
    eigenvec =...
        dlmread(...
        strcat(...
        NMD.str.main,'/AF_eigvec_',int2str(NMD.seed.alloy),'.dat') );
           
%Zero main SED FP: this gets averaged as you loop over the NUM_FFTS      
    Q = zeros(1,NMD.NUM_TSTEPS);
    QDOT = zeros(1,NMD.NUM_TSTEPS);
    ETOT = zeros(1,NMD.NUM_TSTEPS);


%--------------------------------------------------------------------------
tic  
%--------------------------------------------------------------------------
    for ikpt = 1:size(NMD.kptmaster(:,1:3),1)
        for imode = 1:size(NMD.modelist(:,imslice),1)
            
            spatial = 2*pi*1i*(...
    NMD.x0(:,3)*( (NMD.kptmaster(ikpt,1))/(NMD.alat*NMD.Nx) ) +...
    NMD.x0(:,4)*( (NMD.kptmaster(ikpt,2))/(NMD.alat*NMD.Ny) ) +...
    NMD.x0(:,5)*( (NMD.kptmaster(ikpt,3))/(NMD.alat*NMD.Nz) ) );

%             SPATIAL = repmat(spatial,1,NMD.NUM_TSTEPS);
            
%WARNING: :3:, where PRIM has :1: (: implicit) for CONV, must use 
    
    kindex = NMD.kptmaster_index(ikpt);
    
    modeindex = NMD.modelist(imode,imslice);
            
            eigx = repmat(...
                conj(...
                eigenvec(...
                ((NMD.NUM_ATOMS_UCELL*3)*(kindex-1)+1)... 
                :3:...
                ((NMD.NUM_ATOMS_UCELL*3)*kindex),modeindex...
                )...
                ),NMD.NUM_UCELL_COPIES,1);
            
            eigy = repmat(... 
                conj(...
                eigenvec(...
                ((NMD.NUM_ATOMS_UCELL*3)*(kindex-1)+2)... 
                :3:...
                ((NMD.NUM_ATOMS_UCELL*3)*kindex),modeindex...
                )...
                ),NMD.NUM_UCELL_COPIES,1);
            
            eigz = repmat(...
                conj(...
                eigenvec(...
                ((NMD.NUM_ATOMS_UCELL*3)*(kindex-1)+3)... 
                :3:...
                ((NMD.NUM_ATOMS_UCELL*3)*kindex),modeindex...
                )...
                ),NMD.NUM_UCELL_COPIES,1);

            Q = sum(...
                bsxfun(@times,...
                bsxfun(@times, posx, eigx) + ...
                bsxfun(@times, posy, eigy) + ...
                bsxfun(@times, posz, eigz) ...
                , exp(spatial).*(sqrt(m/NMD.NUM_UCELL_COPIES)) )...
                , 1 );

            QDOT = sum(...
                bsxfun(@times,...
                bsxfun(@times, velx, eigx) + ...
                bsxfun(@times, vely, eigy) + ...
                bsxfun(@times, velz, eigz) ...
                , exp(spatial).*(sqrt(m/NMD.NUM_UCELL_COPIES)) )...
                , 1 );

            ETOT =...
		(NMD.freq(modeindex,kindex)^2)*conj(Q).*Q + conj(QDOT).*QDOT;

            EXCORR = xcorr(ETOT,'coeff');
            
        SED.SED(ikpt,:,imode) =...
            SED.SED(ikpt,:,imode) + EXCORR(NMD.NUM_TSTEPS:NMD.NUM_TSTEPS*2-1) ;

        end %END imode
    end %END ikpt
%--------------------------------------------------------------------------
toc 
%--------------------------------------------------------------------------
end %END ifft
    
end %iseed

%seed avg
SED.SED(:,:,:) =...
    SED.SED(:,:,:)/NMD.NUM_SEEDS;


%Define frequencies
time = (1:NMD.NUM_TSTEPS)*(NMD.t_step*NMD.dt);
%Output SED
for imode = 1:size(NMD.modelist(:,imslice),1)
    str_write_single=...
        strcat(NMD.str.main,'/',int2str(NMD.seed.alloy),'/NMD/SED_',...
        num2str(NMD.modelist(imode,imslice)),'.txt');
    output(1:length(time),1) = time;
    output(1:length(time),2) = SED.SED(1,:,imode);
    dlmwrite(str_write_single,output,'delimiter',' ');
    clear output
end %END ikpt  




