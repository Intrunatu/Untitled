function solis = donnes_solis()

% Solis AJACCIO
solis.ajaccio.phi      = 41.9167;  % latitude degre
solis.ajaccio.lambda   =  8.7333;  % longitude degre
solis.ajaccio.altitude = 70;       % altitude en m
solis.ajaccio.zone     = 2;        % type d'aerosol 1=rural 2=maritime 3=urban 4=tropospherique
solis.ajaccio.azimut   = 0;        % azimut en degré
solis.ajaccio.albedo   = 0.25;     % albédo du sol
solis.ajaccio.tilt     =  0;       % angle d'inclinaison en degre
solis.ajaccio.oad      = 0.2;      % prof optique pour aerosol a 700nm
solis.ajaccio.w        = 1.8;      % colonne d'eau en cm

% Solis ODEILLO
solis.odeillo.phi      = 42.493561;   % latitude degre
solis.odeillo.lambda   =  2.029285;   % longitude degre
solis.odeillo.altitude = 1650;     % altitude en m
solis.odeillo.zone     = 2;        % type d'aerosol 1=rural 2=maritime 3=urban 4=tropospherique
solis.odeillo.azimut   = 0;     % azimut en degré
solis.odeillo.albedo   = 0.25;     % albédo du sol
solis.odeillo.tilt     = 0;       % angle d'inclinaison en degre
solis.odeillo.oad      = 0.2;      % prof optique pour aerosol a 700nm
solis.odeillo.w        = 1.8;      % colonne d'eau en cm
end