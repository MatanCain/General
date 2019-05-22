function [saccades_train] = Saccades_train(begin_saccade,end_saccade,time)
%The inputs are a vector with the beginning of the saccades, a vector with the end of the saccades and time which is the length of th trial (scalar) 
%The output is a vector of 0/1 (no saccadess/saccades) with length equal to
%the length of the trial
saccades_train=zeros(1,time);
ii=1;
begin_saccade(begin_saccade>time)=[];
begin_saccade(begin_saccade<0)=[];
end_saccade(end_saccade>time)=[];
end_saccade(end_saccade<0)=[];

if ~isempty(end_saccade) && ~isempty(begin_saccade) && end_saccade(1)<begin_saccade(1)
    saccades_train(1:end_saccade(1))=1;
    end_saccade(1)=[];
end

if  ~isempty(end_saccade) && ~isempty(begin_saccade) && begin_saccade(end)>end_saccade(end)
    saccades_train(begin_saccade(end):end)=1;
    begin_saccade(end)=[];
end

if ~isempty(begin_saccade) && ~isempty(end_saccade)
    for saccade_counter=1:length(begin_saccade)

        while ii<end_saccade(saccade_counter) && ii<time
           if ii<end_saccade(saccade_counter) && ii>=begin_saccade(saccade_counter)
             saccades_train(ii)=1;
           end 
           ii=ii+1;
        end
    end 
end

end% of the funciton 

