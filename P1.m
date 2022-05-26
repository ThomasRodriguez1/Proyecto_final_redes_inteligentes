clear all;
close all;
clc;

%definicion de variables duante la ventana de Backoff
DIFS = 10e-3; % Espacio entre tramas diferencial 
SIFS = 5e-3; % Espacio entre tramas (debido a que la Tx no es instantanea)
durRTS = 11e-3; %ready to send
durCTS = 11e-3; %confirmacion, listo para recibir paquetes
durACK = 11e-3; %paquetes de control
durDATA = 43e-3 ; %paquetes de datos (un solo paquete)
sigma = 1e-3 ; %duracion de cada miniranura

I = 7; % numero de grados
K = 15; %Tamaño maximo del buffer
Epsilon = 18; %Numero de ranuras sleep 

W = [ 16, 32, 64, 128, 256]; %Maximo numero de miniranuras
N = [ 5, 10, 15, 20]; %Numero de nodos por grado
lambda = [ 0.0005, 0.005, 0.03 ] ; % Tasa de generacion de paquetes por segundo


%indices de valores de miniranuras, N°de nodos por grado y del valor de lambda
W_index=1;
N_index=2;
lambda_index=2;

%duracion ranura
T=durDATA+durRTS+durCTS+DIFS+durACK+3*SIFS+sigma.*W(W_index);

%Ciclo de trabajo 
Tc = (2+Epsilon).*T;

tsim = 0.00000000001; % tiempo de simulacion inicia en 0
ta=0; %valor para que ta sea menor a tsim al inicio del n ciclos


%inicializcion de buffers y contador paquetes

Buffer = zeros(I,N(N_index),K); 
Pkt=[];

%variables contadoras
n_paquetes=0;

for t=1:500*Tc

    if ta<tsim
        
        lambda_2=lambda(lambda_index)*N(N_index)*I;
        [ta ,n_paquetes,Buffer,Pkt]=arribo(ta,tsim,lambda_2,N,N_index,I,n_paquetes,Buffer,Pkt);

    end

    tsim = tsim + Tc;
end





%generacion de nuevo paquete y asignacion al buffer
function [ta,n_paquetes,Buffer,Pkt]=arribo(ta,tsim,lambda_2,N,N_index,I,n_paquetes,Buffer,Pkt)

U = (1e6*rand())/1e6; 
%generacion de tiempo aleatorio
nuevot = -(1/lambda_2)*log(1-U);
%nodo y grado aleatorio
nodo_random=randsample(N(N_index),1);
% display(nodo_random)
grado_random= randsample(I,1);
% display(grado_random)

%generacion y asignacion de paquetes

n_paquetes=n_paquetes+1;

Pkt(n_paquetes,1) = n_paquetes;
Pkt(n_paquetes,2) = nodo_random;
Pkt(n_paquetes,3) = grado_random;
Pkt(n_paquetes,4) = ta;

%Verificacion buffer lleno  %1 exitoso 2=Colision 3=Buffer lleno

if Buffer(grado_random,nodo_random,15)==0
    
        Buffer(grado_random,nodo_random,15)=n_paquetes;
        %Recorrer_bufer
else
    
        Pkt(n_paquetes,5)=3;
end



%asignacion de valor nuevo a ta
 fprintf("U: "+nuevot+"\n"); 
ta = tsim + nuevot; 

end








