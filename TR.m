%physical constants
clear all;
close all;
load 'conductive-receivers.mat';
c0    = 2.998e8;
eta0 = 120*pi;
mu0  = pi*4e-7;
eps0 = 1e-9/(36*pi);
%box dimensions
width  = 0.09; % 10cm 
height = width;
length  = width;
%source parameters
f0     = 3e9;
tw     = 1e-8/pi;
t0     = 4*tw;
%spatial discretization
adipose = 10;
tumor   = 60;
sigma   = 1;
epsr    = tumor;
w    = 2 * pi * f0;
k    = (w/c0)*sqrt(epsr-1j*sigma/(w*eps0));
beta = real(k);
c    = w / beta;
lambda = c/f0;
dxmax  = lambda / 10;
dx = dxmax;
dy = dx;
dz = dx;
nx = round(width/dx);
ny = round(height/dy);
nz = round(length/dz);
% material
f0     = 3e9; % GHz
eps = ones(nx,ny,nz) * eps0 * adipose;
sigma = ones(nx,ny,nz) * f0 * 1e-9 * 0.5 - 0.5;
%temporal discretization
dt   = 0.95/(c*sqrt(dx^-2+dy^-2+dz^-2));
%EM field dimensions
Hx = zeros(nx,ny,nz);
Hy = zeros(nx,ny,nz);
Hz = zeros(nx,ny,nz);
Ex = zeros(nx,ny,nz);
Ey = zeros(nx,ny,nz);
Ez = zeros(nx,ny,nz);
%iteration
i = 0;
for n=1:1:n_iter
    %magnetic field derivatives
    Hxy = diff(Hx,1,2);
    Hxz = diff(Hx,1,3);
    Hzx = diff(Hz,1,1);
    Hzy = diff(Hz,1,2);
    Hyx = diff(Hy,1,1);
    Hyz = diff(Hy,1,3);
    %electric field maxwell equations
    epsi = eps(:,2:end-1,2:nz-1);
    ksi = (dt * sigma(:,2:end-1,2:nz-1)) ./ ( 2 * epsi );
    c2 = (1./(1+ksi)).*(dt./epsi);
    c1 = (1-ksi)./(1+ksi);
    Ex(:,2:end-1,2:end-1) = c1.*Ex(:,2:end-1,2:nz-1) - c2.*((1/dy)*Hzy(:,1:end-1,2:end-1) - (1/dz)*Hyz(:,2:ny-1,1:end-1));
    
    epsi = eps(2:end-1,:,2:end-1);
    ksi = (dt * sigma(2:end-1,:,2:end-1)) ./ ( 2 * epsi );
    c2 = (1./(1+ksi)).*(dt./epsi);
    c1 = (1-ksi)./(1+ksi);
    Ey(2:end-1,:,2:end-1) = c1.*Ey(2:end-1,:,2:end-1) - c2.*((1/dz)*Hxz(2:end-1,:,1:end-1) - (1/dx)*Hzx(1:end-1,:,2:end-1));
    
    epsi = eps(2:end-1,2:end-1,:);
    ksi = (dt * sigma(2:end-1,2:end-1,:)) ./ ( 2 * epsi );
    c2 = (1./(1+ksi)).*(dt./epsi);
    c1 = (1-ksi)./(1+ksi);
    Ez(2:end-1,2:end-1,:) = c1.*Ez(2:end-1,2:end-1,:) - c2.*((1/dx)*Hyx(1:end-1,2:end-1,:) - (1/dy)*Hxy(2:end-1,1:end-1,:));
   
    %TR sources
    for k=1:1:nrec
        Ez(recx, recdy * k, recz) = Ez(recx, recdy * k, recz) + rec(k, n);
    end
    
    %electric field derivatives
    Exy = diff(Ex,1,2);
    Exz = diff(Ex,1,3);
    Ezx = diff(Ez,1,1);
    Ezy = diff(Ez,1,2);
    Eyx = diff(Ey,1,1);
    Eyz = diff(Ey,1,3);
    
    %magnetic field maxwell equations
    Hx(:,1:end-1,1:end-1) = Hx(:,1:end-1,1:end-1) + (dt/(mu0*dy))*Ezy(:,:,1:end-1) - (dt/(mu0*dz))*Eyz(:,1:end-1,:);
    Hy(1:end-1,:,1:end-1) = Hy(1:end-1,:,1:end-1) + (dt/(mu0*dz))*Exz(1:end-1,:,:) - (dt/(mu0*dx))*Ezx(:,:,1:end-1);
    Hz(1:end-1,1:end-1,:) = Hz(1:end-1,1:end-1,:) + (dt/(mu0*dx))*Eyx(:,1:end-1,:) - (dt/(mu0*dy))*Exy(1:end-1,:,:);
    %display
    if (mod(i,5)==0)
        slice(:,:)=Ez(round(nx/2),:,:);
        pcolor(slice');
        colorbar;
        drawnow
    end
    i = i+1;
    disp(i)
end
