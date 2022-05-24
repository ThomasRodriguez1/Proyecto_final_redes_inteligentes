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
lambda = [ 0.0005, 0 .005, 0.03 ] ; % Tasa de generacion de paquetes por segundo
tsim = 0; % tiempo de simulacion inicia en 0

%duracion ranura
T=durDATA+durRTS+durCTS+DIFS+durACK+3*SIFS+sigma.*W;

%Ciclo de trabajo 
Tc = (2+Epsilon).*T;

for t=1:300000*Tc

    if ta<tsim
        
        lambda_2=lambda(1)*N(n)*I;
        ta=arribo(tsim,lambda2);
        
    end


end

function []








