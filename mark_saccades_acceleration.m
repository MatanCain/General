
function mark_saccades_acceleration(session, sufix, first, last, trial_name)

% maestro definitions
XPOS_INX = 1;
YPOS_INX = 2;
XVEL_INX = 3;
YVEL_INX = 4;
HVEL_INX = 5;

% constants 
SD_SMOOTH = 5;
ACC_THRSHOLD = 1000;
VEL_THRSHOLD_DURING_MOVE = 50; % velocity threshold for movement 
VEL_THRSHOLD_PRE_MOVE = 15; % velocity threshold for fixation 
PRE_SAC = 10; % time before threshold crossing
POST_SAC = 10; % time after threshold crossing
MERGE_SAC = 50; % merge saccades in case they are closer than merge value
MIN_BLINK_LENGTH = 50;
 
% when target off use very strict criteria
REACT_TIME = 60;
MOVE_RELAX = 250; % est. time from the end of the movement to relaxation
old_dir = cdp(session); % cd to data directory
 
all_data = getmdata( [sufix ',' trial_name], first, last);
 
for i=1:length(all_data)
     
    for j=1:length(all_data(i).data)
        if(isfield(all_data(i), 'others') && ~isempty(all_data(i).others))
            o = all_data(i).others(j,:);
        else
            o = [];
        end
        
        hvel = all_data(i).targets(j).hvel + all_data(i).targets(j).patvelH;
        vvel = all_data(i).targets(j).vvel + all_data(i).targets(j).patvelV;
        [tb te]= ...
            get_target_init_and_end(hvel, vvel,[],[],all_data(i).failed(j));
        assert(length(tb)<=1); assert(length(te)<=1)
        

        % ------- detect saccades
        vel = all_data(i).data{j}([XVEL_INX YVEL_INX], :);        
        raw_speed = sqrt(vel(1,:).^2+vel(2,:).^2);
        % smooth
        speed = smooth_psth(raw_speed,SD_SMOOTH);
       
        % each componenet seperatly
        v_smooth = [];
        v_smooth(1,:) = smooth_psth(vel(1,:), SD_SMOOTH);
        v_smooth(2,:) = smooth_psth(vel(2,:), SD_SMOOTH);
        acc = diff(v_smooth')*1000;
        abs_acc = sqrt(sum(acc.^2,2));
        
%         acc = diff(speed)*1000;
%         abs_acc = abs(acc);
        
        abs_acc = [0 abs_acc']; % dummy
        len = length(abs_acc);
        
        sacc_bool = zeros(1,len);
        in_sac = 0;
 
        % detect all threshold crossing
        for k=1:len
            if(isempty(tb) || k<tb+REACT_TIME || k> te+ MOVE_RELAX)
                c_vel_thr = VEL_THRSHOLD_PRE_MOVE;
            else
                c_vel_thr = VEL_THRSHOLD_DURING_MOVE;
            end
                
            if(abs_acc(k) > ACC_THRSHOLD || speed(k) > c_vel_thr) 
                if(~in_sac)
                    in_sac =1;
                end
            else
                if(in_sac) % mark end of saccade
                    in_sac = 0;
                end
            end
            sacc_bool(k) = in_sac;
            
        end % end j=1:size(vec,2)
        
        %  --- add blinks
        c_blinks= all_data(i).blinks{j};
     
        for k=1:size(c_blinks,1)
            if(c_blinks(k,2)- c_blinks(k,1) < MIN_BLINK_LENGTH)
                continue;
            end
            b_init = c_blinks(k,1);
            if(b_init <=0)
                b_init=1;
            end
            b_end = c_blinks(k,2);
            if(b_end>len)
                b_end = len;
            end
            sacc_bool(b_init:b_end) =1;
            
        end
        % convert to markers
        bound  =get_nan_boundaries(sacc_bool',1);
        if(isempty(bound))
           continue;
        end
        
        mark1_tmp = cell2mat({bound.beg});
        mark2_tmp = cell2mat({bound.end});
        
        
        % stretch saccade by PRE and POST  saccade parameters
        mark1_tmp = mark1_tmp - PRE_SAC;
        mark2_tmp = mark2_tmp + POST_SAC;
        
        % deal with edge
        mark1_tmp(mark1_tmp <= 0) =1;
        mark2_tmp(mark2_tmp >= len) = len-1;
        
        % combine close threshold crossing
        mark1 = [];
        mark1(1) = mark1_tmp(1);
        mark2 =[];
        for k= 2:length(mark1_tmp)
            if(mark1_tmp(k) - MERGE_SAC <mark2_tmp(k-1))
                continue;
            else % saccade do not overlap
                mark1(end+1) = mark1_tmp(k);
                mark2(end+1) = mark2_tmp(k-1);
            end
        end
        mark2(end+1) = mark2_tmp(end);
        % could happen in failed files
%         last = find( ~isnan(vel(1,:)) & ~isnan(vel(2,:)), 1, 'last');
%         mark1(mark1>last) = last;
%         mark2(mark2>last) = last;
        %--------------
        
        % --- save cut       
        name = sprintf('%s%s.%04d',session, sufix,all_data(i).trialnums(j));
        d = readcxdata(name);
        if(~isempty(d.cut))
            continue;
        end
            
        if(isequal(session(1:2), 'zp') ||  isequal(session(1:2), 'au'))
            %error('currently do not support but see code below and check it');
          
            % use Javiar style to mark saccades
            d.cut  = [mark1', mark2', repmat(3,length(mark1), 1)];
            d.cut  = [d.cut; [mark1', mark2', repmat(2,length(mark1), 1)]];
        else
            d.mark1 = mark1;
            d.mark2 = mark2;
        end
        d.discard = 0;
        editcxdata(name, d);
        %figure; plot(raw_speed'); hold on; plot(mark1,30,'r*'); plot(mark2,30,'g*'); 
    end
end
cd(old_dir);
end