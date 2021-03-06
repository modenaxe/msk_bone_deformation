%-------------------------------------------------------------------------%
%    Copyright (c) 2021 Modenese L.                                       %
%    Author:   Luca Modenese,  2021                                       %
%    email:    l.modenese@imperial.ac.uk                                  %
% ----------------------------------------------------------------------- %
function osimModel = applyTorsionToMuscleAttachments(osimModel, aSegmentName, aTorsionAxisString, torsion_angle_func_rad)

import org.opensim.modeling.*

% default: deform viapoints (legacy option)
deformViapoint = 'yes';

disp('------------------------------');
disp(' ADJUSTING MUSCLE ATTACHMENTS ');
disp('------------------------------');

% check if segment is included in the model
if osimModel.getBodySet().getIndex(aSegmentName)<0
    error('The specified segment is not included in the OpenSim model')
end

% converting the axis in the index used later
[RotMat, axis_ind] = getAxisRotMat(aTorsionAxisString);

% extracting muscleset
Muscles = osimModel.getMuscles();
N_mus = Muscles.getSize();
processed_muscles = '';
ntm = 1;
% loop through the muscles
for n_mus = 0:N_mus-1
    
    % current muscles
    curr_Mus = Muscles.get(n_mus);
    
    % extracting the path
    currentPathPointSet = curr_Mus.getGeometryPath().getPathPointSet();
    
    % number of points
    N_p = currentPathPointSet.getSize();
    
    % looping through the points of the PathPointSet
    for n_p = 0:N_p-1
        
        % skip the point if viapoints are not be deformed
        if strcmp(deformViapoint,'no') && (n_p~=0 || n_p~=N_p-1)
            continue
        end
        
        % Body attached to each point of the PathPointSet
        attachBodyName = char(currentPathPointSet.get(n_p).getBody().getName());
        
        if strcmp(attachBodyName, aSegmentName)
            
%             disp(['processing', char(curr_Mus.getName())]);
            
            % keep track 
            if max(strcmp(char(curr_Mus.getName()), processed_muscles))==0
                processed_muscles{ntm} = char(curr_Mus.getName());
                ntm = ntm + 1;
            end
            % point coordinates
            musAttachLocVec3 =  currentPathPointSet.get(n_p).getLocation();
            
            % convert to Matlab var
            musAttachLocCoords = [musAttachLocVec3.get(0),musAttachLocVec3.get(1),musAttachLocVec3.get(2)];
            
            % compute torsion metric for the attachment point
            TorsRotMat = RotMat(torsion_angle_func_rad(musAttachLocCoords(axis_ind)));
            
            % compute new muscle attachment coordinates
            new_musAttachLocCoords = (TorsRotMat*musAttachLocCoords')';%musCoord * M'
            
            % setting the muscle PathPointSet
            currentPathPointSet.get(n_p).setLocationCoord(0,double(new_musAttachLocCoords(1)))
            currentPathPointSet.get(n_p).setLocationCoord(1,double(new_musAttachLocCoords(2)))
            currentPathPointSet.get(n_p).setLocationCoord(2,double(new_musAttachLocCoords(3)))
        end
    end
end

disp(['Processed ', num2str(ntm-1), ' muscles:'])
print_str = '';
for nd = 1:length(processed_muscles)
   if mod(nd, round((ntm-1)/2))==0
        disp(print_str);
        print_str = '';
   end
    print_str = [print_str, processed_muscles{nd}, '   '];
end
% remaining muscles
print_str = [print_str, processed_muscles{nd}, '   '];
end