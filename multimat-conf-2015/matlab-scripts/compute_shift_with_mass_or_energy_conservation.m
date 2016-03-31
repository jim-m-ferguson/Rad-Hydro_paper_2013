% clear all; close all; clc;function [diff_mass] = compute_shift_with_mass_or_energy_conservation(numeric_filename,options,...                                              exact_filename, x_offset)    % numeric_filename = file storing the numerical solution% options = quadrature points, interpolation type, index of the numerical% solution% exact_filename = used to pass the text files storing the exact solution (x,rho,eps,v,temp)% name of the variablesvariable_names = {'density'; 'radiation'; 'mach'; 'material temperature'};% load data from exact and numeric filenamesnb_exact_file = size(exact_filename);for ifile=1:nb_exact_file(2)   file_id = fopen(exact_filename{ifile});   exact_value(:,ifile) = textread(exact_filename{ifile}, '%f');   fclose(file_id);   endfornb_exact = size(exact_value(:,1));nb_exact = nb_exact(1);% make sure the x-values from the exact solution are linearly increasing % (remove values with the same x-coord)[exact_value_unique(:,1), index_unique] = unique(exact_value(:,1));for ifile=2:nb_exact_file(2)    exact_value_unique(:,ifile) = exact_value(index_unique,ifile);endfor%index for numerical solutionindex_num = options.index;nb_index_num = size(options.index);assert(nb_index_num(1)==nb_exact_file(2),'the number of exact files does not match the number of indexes for the numerical solutions.');% load vectors from 'num_filename'numeric = csvread(numeric_filename,1,0);for i=1:nb_index_num(1)    numeric_value(:,i) = numeric(:,index_num(i));endfor% normalize the variables for both exact and numerical values. % No need to do it for mach number and density.for i=2:nb_index_num(1)    exact_value(:,i) = exact_value(:,i) / exact_value(1,i);    numeric_value(:,i) = numeric_value(:,i) / numeric_value(1,i);    endforsgn=sign(x_offset);x_offset=min(abs(x_offset),min(abs(exact_value(1,1)-numeric_value(1,1)), abs(exact_value(end,1)-numeric_value(end,1))));x_offset=sgn*min(x_offset, 1.e-3);exact_value_unique(:,1) = exact_value_unique(:,1) - x_offset;% get number of cells and return the valuen_cells = size(numeric_value(:,1))-1;n_cells = n_cells(1);% load 1d quadrature[xq,wq] = GLNodeWt(options.nquad);% jacobian termjac = 0.5 * (numeric_value(end,1)-numeric_value(1,1)) / n_cells;% load test functionsf = Lagrange_poly(xq,1);% initialize normsmass_exact = zeros(nb_index_num(1)-1,1);mass_num = zeros(nb_index_num(1)-1,1);diff_mass = zeros(nb_index_num(1)-1,1);% initialize integerindex_left = 1;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% loop over the cells of the numerical mesh %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%for i_cell=1:1:n_cells% coordinates of the nodes belonging to cell 'i_cell'node_cell_coord = numeric_value(i_cell:i_cell+1,1);diff_node = node_cell_coord(2)-node_cell_coord(1);sum_node = node_cell_coord(1)+node_cell_coord(2);% coordinates of the quadrature points in the real meshxq_coord = xq*0.5*diff_node+0.5*sum_node;% find node of the semi-analytical mesh that is the closest from the left% to 'xq_coord(1)'while (exact_value_unique(index_left,1)<node_cell_coord(1))    index_left = index_left+1;endwhileindex_right = index_left;while (exact_value_unique(index_right,1)<node_cell_coord(end))    index_right = index_right+1;endwhileif (i_cell ~= 1)     index_left = index_left-1; endifif(i_cell ~= n_cells)    index_right = index_right+1;endif% interpolate the values of the exact solution at the quadrature points% (only for rho, eps, mach and temp)exact_xq = zeros(options.nquad,nb_exact_file(2)-1);if (xq_coord(1)<exact_value_unique(index_left,1))  i_cell, xq_coord, exact_value_unique(index_left,1), x_offsetelseif (xq_coord(end)>exact_value_unique(index_right,1))  i_cellendiffor ifile=2:nb_exact_file(2)    exact_xq(:,ifile-1) = interp1(exact_value_unique(index_left:index_right,1), exact_value_unique(index_left:index_right,ifile), xq_coord, options.interpolation_type);endfor% interpolate the values of the numerical solution at the quadrature pointsnumeric_xq = zeros(options.nquad,nb_exact_file(2)-1);for ifile=2:nb_index_num(1)    for nq=1:options.nquad        numeric_xq(nq,ifile-1) = dot(numeric_value(i_cell:i_cell+1,ifile),f(nq,:));    endforendfor% compute the cell contribution to the L1 and L2 normsfor i=1:nb_index_num(1)-1    mass_exact(i) = mass_exact(i) + dot(wq,exact_xq(:,i))*jac;    mass_num(i) = mass_num(i) + dot(wq,numeric_xq(:,i))*jac;    diff_mass(i) = diff_mass(i) + dot(wq,exact_xq(:,i)-numeric_xq(:,i))*jac;endfor% set index_left equal to index_right-1 to speed up next searchindex_left = index_right-1;endfor % end of loop over cellsdiff_mass=abs(diff_mass);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% print the values of the norms %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%if (options.output)    for i=1:nb_index_num(1)-1%        fprintf('L1 norm in domain for the %s is: %12.7e \n', variable_names{i}, normL1(i));%        fprintf('L2 norm in domain for the %s is %12.7e \n \n', variable_names{i}, normL2(i));    %        fprintf('----------------------------------------------------------- \n');        endforendifend % end function