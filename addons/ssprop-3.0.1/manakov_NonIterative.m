function [u1x,u1y] = manakov_NonIterative(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma,psp,method)

% This function corresponds to the sspropv function modified to account for
% the Manakov solution of the NLSE. For help on the parameters, please se
% sspropv.m below:

% This function solves the coupled nonlinear Schrodinger equations for
% pulse propagation in an optical fiber using the split-step
% Fourier method.
% 
% The following effects are included in the model: group velocity
% dispersion (GVD), higher order dispersion, polarization
% dependent loss, arbitrary fiber birefringence, and
% self-phase modulation. 
%
% USAGE
%
% [u1x,u1y] = sspropv(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma);
% [u1x,u1y] = sspropv(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma,psp);
% [u1x,u1y] = sspropv(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma,psp,method);
% [u1x,u1y] = sspropv(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma,psp,method,maxiter;
% [u1x,u1y] = sspropv(u0x,u0y,dt,dz,nz,alphaa,alphab,betapa,betapb,gamma,psp,method,maxiter,tol);
%
%
% INPUT
%
% u0x, u0y        Starting field amplitude components
% dt              Time step
% dz              Propagation step size
% nz              Number of steps to take (i.e. L = dz*nz)
% alphaa, alphab  Power loss coefficients for the two eigenstates
%                   (see note (2) below)
% betapa, betapb  Dispersion polynomial coefs, [beta_0 ... beta_m] 
%                   for the two eigenstates (see note (3) below)
% gamma           Nonlinearity coefficient
% psp             Polarization eigenstate (PSP) of fiber, see (4)
% method          Which method to use, either ’circular’ or ’elliptical’ 
%                   (default = ’elliptical’, see instructions)
% tol             Convergence tolerance (default = 1e-5)
%
%
% OUTPUT
%
% u1x, u1y        Output field amplitudes
%
%
% NOTES
%
% (1) The dimensions of the input and output quantities can
% be anything, as long as they are self consistent.  E.g., if 
% |u|^2 has dimensions of Watts and dz has dimensions of
% meters, then gamma should be specified in W^-1*m^-1.
% Similarly, if dt is given in picoseconds, and dz is given in
% meters, then beta(n) should have dimensions of ps^(n-1)/m.
%
% (2) The loss coefficients (alpha) may optionally be specified
% as a vector of the same length as u0, in which case it is
% treated as vector that describes alpha(w) in the frequency
% domain. (The function wspace.m in the tools subdirectory can
% be used to construct a vector with the corresponding
% angular frequencies.) 
%
% (3) The propagation constant beta(w) can also be specified
% directly by replacing the polynomial argument betap with a
% vector of the same length as u0. In this case, the argument
% betap is treated as a vector describing propagation in the
% frequency domain. 
%
% (4) psp describes the polarization eigenstates of the fiber. If
% psp is a scalar, it gives the orientation of the linear
% birefringence axes relative to the x-y axes.  If psp is a
% vector of length 2, i.e., psp = [psi,chi], it describes the
% describes the ellipse orientation and ellipticity of the
% first polarization eigenstate.  Specifically, (2*psi,2*chi)
% are the% longitude and lattitude of the principal eigenstate
% on the Poincare sphere.  
%
% 
% AUTHORS:  Afrouz Azari (afrouz@umd.edu)
%           Ross A. Pleban (rapleban@ncsu.edu)
%           Reza Salem (rsalem@umd.edu)
%           Thomas E. Murphy (tem@umd.edu)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Copyright 2006, Thomas E. Murphy
%
%   This file is part of SSPROP.
%
%   SSPROP is free software; you can redistribute it and/or
%   modify it under the terms of the GNU General Public License
%   as published by the Free Software Foundation; either version
%   2 of the License, or (at your option) any later version.
%
%   SSPROP is distributed in the hope that it will be useful, but
%   WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public
%   License along with SSPROP; if not, write to the Free Software
%   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
%   02111-1307 USA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Obs: this function only implements the Manakov model in circular
% coordinates mode.


if (nargin<10)
  error('Not enough input arguments')
end

if (nargin<11)
    psp = [0,0];
end

if (nargin<12)
    method='circular';
end


nt = length(u0x);
w = 2*pi*[(0:nt/2-1),(-nt/2:-1)]'/(dt*nt) ;

if isscalar(psp)
  psi = psp(1);               % Orientation of birefringent axes
  chi = 0;                    % (linear birefringence)
else
  psi = psp(1);               % Orientation of polarization ellipse
  chi = psp(2);               % Ellipticity parameter
end

if (length(alphaa) == nt)     % If the user manually specifies alpha(w)
  ha = -alphaa/2;
else
  ha = 0;
  for ii = 0:length(alphaa)-1;
    ha = ha - alphaa(ii+1)*(w).^ii/factorial(ii);
  end
  ha = ha/2;
end

if (length(betapa) == nt)     % If the user manually specifies beta(w)
  ha = ha - 1i*betapa;
else
  for ii = 0:length(betapa)-1;
    ha = ha - 1i*betapa(ii+1)*(w).^ii/factorial(ii);
  end
end

ha = exp(ha.*dz/2);      % ha = exp[(-alphaa/2 - j*betaa)*dz/2])

if (length(alphab) == nt)
  hb = -alphab/2;
else
  hb = 0;
  for ii = 0:length(alphab)-1;
    hb = hb - alphab(ii+1)*(w).^ii/factorial(ii);
  end
  hb = hb/2;
end

if (length(betapb) == nt)
  hb = hb - 1i*betapb;
else
  for ii = 0:length(betapb)-1;
    hb = hb - 1i*betapb(ii+1)*(w).^ii/factorial(ii);
  end
end

hb = exp(hb.*dz/2);     % hb = exp[(-alphab/2 - j*betab)*dz/2])

if strcmp(method,'circular')   %% CIRCULAR BASIS METHOD %%
    
  % First, rotate coordinates to circular basis:
  u0a = (1/sqrt(2)).*(u0x + 1i*u0y);
  u0b = (1/sqrt(2)).*(1i*u0x + u0y);
  
  % Propagation matrix for linear calcuations
  
  h11 = ( (1+sin(2*chi))*ha + (1-sin(2*chi))*hb )/2;
  h12 = -1i*exp(+1i*2*psi)*cos(2*chi)*(ha-hb)/2;
  h21 = +1i*exp(-1i*2*psi)*cos(2*chi)*(ha-hb)/2;
  h22 = ( (1-sin(2*chi))*ha + (1+sin(2*chi))*hb )/2;
  
  u1a = u0a;
  u1b = u0b;
  uafft = fft(u0a);
  ubfft = fft(u0b);

  for iz = 1:nz,
    % Calculate 1st linear half
    uahalf = ifft( h11.*uafft + h12.*ubfft );
    ubhalf = ifft( h21.*uafft + h22.*ubfft );
          
      % Calculate nonlinear section using the MANAKOV aproximation:      
      uva = uahalf.*exp( (-1i*(8/9)*gamma*dz).*((abs(u0a).^2 + abs(u1a).^2)/2 + (abs(u0b).^2 + abs(u1b).^2)/2));                         
      uvb = ubhalf.*exp( (-1i*(8/9)*gamma*dz).*((abs(u0b).^2 + abs(u1b).^2)/2 + (abs(u0a).^2 + abs(u1a).^2)/2));
      
      uva = fft(uva);
      uvb = fft(uvb); 
      
      % Calculate 2nd linear half
      uafft = h11.*uva + h12.*uvb;
      ubfft = h21.*uva + h22.*uvb;
      uva = ifft(uafft);
      uvb = ifft(ubfft);
      
%       if ( ( sqrt(norm(uva-u1a,2).^2+norm(uvb-u1b,2).^2) / ...
%              sqrt(norm(u1a,2).^2+norm(u1b,2).^2) ) < tol )
%         % tolerances met
%         u1a = uva;
%         u1b = uvb;       
%       else
        % tolerances not met
        u1a = uva;
        u1b = uvb;
%         warning('Specified tolerance for SSFM not met.')
%       end
          
    u0a = u1a;
    u0b = u1b;
    
  end %end step iteration
  
  % Rotate back to x-y basis:
  u1x = (1/sqrt(2)).*(u1a-1i*u1b) ;
  u1y = (1/sqrt(2)).*(-1i*u1a+u1b) ; 

else
  error('Invalid method specified: %s\n', method);
end

end
