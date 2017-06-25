classdef Model < handle
  
  properties
    % Parameters
    temperature
    bandwidth
    power_BS
    power_MD
    gain_T
    gain_R
    height_BS
    height_MD
    num_MD
    num_BS
    simulation_time
    simulation_time_left
    handover_policy
    path_loss_model
    link
    speed
    measureInterval
    s_fading
    sigma_fading
    sigma_shadowing
    
    % Positions of BSs
    boundary_x
    boundary_y
    v_x
    v_y
    
    % Mobile Devices
    MD = MobileDevice( 0, 0, 0, 0 )
    MD_tmp = MobileDevice( 0, 0, 0, 0 )
    
    % Model Parameters
    count_handover
    count_disconnection
    isStop
    isPause
    noise
    timer
    RicianDistribution
    fadingOrNot
    
    % Display
    disp_simulation_time_left
    disp_count_handover
    disp_count_disconnection
    
  end
  
  properties( Constant )
    % Handover Policy
    EAGER                = 1;
    LAZY                 = 2;
    THRESHOLD            = 3;
    HARD_THRESHOLD       = 4;
    
    % Path-loss Model
    TWORAY               = 1;
    SMOOTH               = 2;
    COST231              = 3;
    
    % Link Direction
    UP                   = 1;
    DOWN                 = 2;
    
    % Parameters
    ISR                  = 500;
    R                    = 500 / 3 ^ 0.5;
    freq_reuse_factor    = 1;
    num_CBS_extend       = 6;
      
    % Positions of BSs
    x_BS                 = 500 * sqrt(3) .* [ 0, 1, 1, 1, 0.5, 0.5, 0.5, 0.5, 0, 0, 0, 0, -0.5, -0.5, -0.5, -0.5, -1, -1, -1 ];
    y_BS                 = 500 .* [ 0, 1, 0, -1, 1.5, 0.5, -0.5, -1.5, 2, 1, -1, -2, 1.5, 0.5, -0.5, -1.5, 1, 0, -1 ];
    x_CBS_extend         = 500 * sqrt( 3 ) .* [ 2.5, 1.5, -1, -2.5, -1.5, 1 ];
    y_CBS_extend         = 500 .* [ -0.5, 3.5, 4, 0.5, -3.5, -4 ];
  end
  
  methods
    
    function obj = Model()
      
      % Parameters
      obj.temperature          = 27 + 273.15;
      obj.bandwidth            = 10 * 10 ^ 6;
      obj.power_BS             = 33;
      obj.power_MD             = 23;
      obj.gain_T               = 14;
      obj.gain_R               = 14;
      obj.height_BS            = 51.5;
      obj.height_MD            = 1.5;
      obj.num_MD               = 300;
      obj.num_BS               = 19;
      obj.simulation_time      = 300;
      obj.handover_policy      = obj.EAGER;
      obj.path_loss_model      = obj.TWORAY;
      obj.link                 = obj.UP;
      obj.speed                = 10;
      obj.measureInterval      = 1;
      obj.s_fading             = 0;
      obj.sigma_fading         = 0;
      obj.sigma_shadowing      = 0;

      % Model Parameters
      obj.isStop                = true;
      obj.isPause               = false;
      obj.noise                 = thermal_noise_power( obj.temperature, obj.bandwidth );
      obj.RicianDistribution    = makedist( 'Rician', 's', 0, 'sigma', 1 );
      obj.fadingOrNot           = false;
      
      % Initial Plot
      obj.v_x = obj.R * cos( -( 0:6 ) * pi / 3 ) + obj.x_BS.';
      obj.v_y = obj.R * sin( -( 0:6 ) * pi / 3 ) + obj.y_BS.';
      for i = 1:obj.num_BS
        [ obj.boundary_x, obj.boundary_y ] = polybool( 'union', obj.boundary_x, obj.boundary_y, obj.v_x( i, : ), obj.v_y( i, : ) );
      end
      obj.boundary_x( 2:7, : ) = obj.boundary_x + obj.x_CBS_extend.';
      obj.boundary_y( 2:7, : ) = obj.boundary_y + obj.y_CBS_extend.';

      count = 1;
      while count <= obj.num_MD
        id_BS = randi( obj.num_BS );
        x_temp = obj.R - 2 * obj.R * rand + obj.x_BS( id_BS );
        y_temp = obj.R - 2 * obj.R * rand + obj.y_BS( id_BS );
        if inpolygon( x_temp, y_temp, obj.v_x( id_BS, : ), obj.v_y( id_BS, : ) ) == 1
          obj.MD( count ) = MobileDevice( id_BS, x_temp, y_temp, obj.speed );
          count = count + 1;
        end
      end
      
      obj.simulation_time_left = obj.simulation_time;
      obj.MD_tmp = obj.MD;
      obj.count_handover = 0;
      obj.count_disconnection = 0;
      
      obj.disp_simulation_time_left = annotation('textbox', [0.53 0.66 0.15 0.02],...
          'FontSize', 16,...
          'EdgeColor', 'none');
      obj.disp_count_handover = annotation('textbox', [0.715 0.66 0.15 0.02],...
          'FontSize', 16,...
          'EdgeColor', 'none');
      obj.disp_count_disconnection = annotation('textbox', [0.89 0.66 0.15 0.02],...
          'FontSize', 16,...
          'EdgeColor', 'none');
      
      obj.render()
      
    end
    
    function obj = check( obj )
      % calculate SINR
      distance = ( ( obj.x_BS.' - [ obj.MD_tmp.x ] ) .^ 2 + ( obj.y_BS.' - [ obj.MD_tmp.y ] ) .^ 2 ) .^ 0.5;
      received_power = normrnd( 0, obj.sigma_shadowing ) + obj.fadingOrNot * watt_2_dB( random( obj.RicianDistribution ) ^ 2 );
      
      if obj.path_loss_model == obj.TWORAY
        received_power = received_power + watt_2_dB( two_ray_ground_model( obj.height_MD, obj.height_BS, distance ) );
      elseif obj.path_loss_model == obj.SMOOTH
        received_power = received_power + watt_2_dB( smooth_transition_model( distance ) );
      else
        disp( watt_2_dB( cost_231_model( obj.height_BS, obj.height_MD, distance ) ) );
        received_power = received_power + watt_2_dB( cost_231_model( obj.height_BS, obj.height_MD, distance ) );
      end

      if obj.link == obj.UP
        received_power = received_power + dBm_2_dB( obj.power_MD ) + obj.gain_T + obj.gain_R;
        received_power_sum = sum( dB_2_watt( received_power ), 2 );
        interference = received_power_sum - dB_2_watt( received_power );
      else
        received_power = received_power + dBm_2_dB( obj.power_BS ) + obj.gain_T + obj.gain_R;
        received_power_sum = sum( dB_2_watt( received_power ), 1 );
        interference = received_power_sum - dB_2_watt( received_power );
      end
      sinr = SINR( received_power, interference, obj.noise );

      % check connection
      for j = 1:obj.num_MD
        if obj.link == obj.UP
          if sinr( obj.MD_tmp( j ).id_BS, j ) < -55
            obj.count_disconnection = obj.count_disconnection + 1;
            [ maxSINR, maxBS ] = max( sinr( :, j ) );
            obj.MD_tmp( j ).id_BS = maxBS;
          end
        else
          if sinr( obj.MD_tmp( j ).id_BS, j ) < -10
            obj.count_disconnection = obj.count_disconnection + 1;
            [ maxSINR, maxBS ] = max( sinr( :, j ) );
            obj.MD_tmp( j ).id_BS = maxBS;
          end
        end
      end

      obj.timer = obj.timer + 1;
      if obj.timer == obj.measureInterval
        obj.timer = 0;
        % update id_BS if necessary
        if obj.handover_policy == obj.EAGER
          for j = 1:obj.num_MD
            [ maxSINR, maxBS ] = max( sinr( :, j ) );
            if maxBS ~= obj.MD_tmp( j ).id_BS
              obj.MD_tmp( j ).id_BS = maxBS;
              obj.count_handover = obj.count_handover + 1;
            end
          end
        elseif obj.handover_policy == obj.LAZY
          for j = 1:obj.num_MD
            [ maxSINR, maxBS ] = max( sinr( :, j ) );
            if maxBS ~= obj.MD_tmp( j ).id_BS
              obj.MD_tmp( j ).handover_timeLeft = obj.MD_tmp( j ).handover_timeLeft - 1;
              if obj.MD_tmp( j ).handover_timeLeft == 0
                obj.MD_tmp( j ).id_BS = maxBS;
                obj.MD_tmp( j ).handover_timeLeft = 5;
                obj.count_handover = obj.count_handover + 1;
              end
            end
          end
        elseif obj.handover_policy == obj.THRESHOLD
          for j = 1:obj.num_MD
            [ maxSINR, maxBS ] = max( sinr( :, j ) );
            if maxBS ~= obj.MD_tmp( j ).id_BS
              if maxSINR > -50
                obj.MD_tmp( j ).id_BS = maxBS;
                obj.count_handover = obj.count_handover + 1;
              end
            end
          end
        else
          for j = 1:obj.num_MD
            [ maxSINR, maxBS ] = max( sinr( :, j ) );
            if maxBS ~= obj.MD_tmp( j ).id_BS
              if maxSINR > sinr( obj.MD_tmp( j ).id_BS, j ) +   3
                obj.MD_tmp( j ).id_BS = maxBS;
                obj.count_handover = obj.count_handover + 1;
              end
            end
          end
        end
      end
      
      
    end
    
    function obj = start( obj )
      
      if obj.isStop == true
        obj.MD_tmp = obj.MD;
        obj.simulation_time_left = obj.simulation_time;
        obj.check();
        obj.count_handover = 0;
        obj.count_disconnection = 0;
        obj.isStop = false;
        obj.timer = 0;
        obj.render();
      end
      obj.isPause = false;
      
      while obj.simulation_time_left > 0
        
        if obj.isStop == true
          break
        elseif obj.isPause == true
          break
        end
        
        obj.simulation_time_left = obj.simulation_time_left - 1;

        obj.check();

        % mobile devices move
        for j = 1:obj.num_MD
          obj.MD_tmp( j ) = obj.MD_tmp( j ).move();
          if inpolygon( obj.MD_tmp( j ).x, obj.MD_tmp( j ).y, obj.boundary_x( 1, : ), obj.boundary_y( 1, : ) ) == 0
            for i = 2:(obj.num_CBS_extend + 1)
              if inpolygon( obj.MD_tmp( j ).x, obj.MD_tmp( j ).y, obj.boundary_x( i, : ), obj.boundary_y( i, : ) ) == 1
                obj.MD_tmp( j ).x = obj.MD_tmp( j ).x - obj.x_CBS_extend( i-1 );
                obj.MD_tmp( j ).y = obj.MD_tmp( j ).y - obj.y_CBS_extend( i-1 );
                break;
              end
            end
          end
        end
        
        obj.render()
        pause( 0.1 )
        
      end
      
      if obj.isPause == false
        if obj.isStop == false
          obj.MD_tmp = obj.MD;
          obj.simulation_time_left = obj.simulation_time;
          obj.check();
          obj.count_handover = 0;
          obj.count_disconnection = 0;
        end
      end
      
    end
    
    function obj = initialize( obj )

      count = 1;
      obj.MD = MobileDevice( 0, 0, 0, 0 );
      while count <= obj.num_MD
        id_BS = randi( obj.num_BS );
        x_temp = obj.R - 2 * obj.R * rand + obj.x_BS( id_BS );
        y_temp = obj.R - 2 * obj.R * rand + obj.y_BS( id_BS );
        if inpolygon( x_temp, y_temp, obj.v_x( id_BS, : ), obj.v_y( id_BS, : ) ) == 1
          obj.MD( count ) = MobileDevice( id_BS, x_temp, y_temp, obj.speed );
          count = count + 1;
        end
      end
      
      obj.simulation_time_left = obj.simulation_time;
      obj.MD_tmp = obj.MD;
      obj.check();
      obj.count_handover = 0;
      obj.count_disconnection = 0;
      obj.noise = thermal_noise_power( obj.temperature, obj.bandwidth );
      obj.timer = 0;
      obj.RicianDistribution = makedist( 'Rician', 's', obj.s_fading, 'sigma',dB_2_watt( obj.sigma_fading ) );
      
      obj.render()
      
    end
    
    function obj = render( obj )
      %uistack(obj.disp_simulation_time_left,'top');
      %uistack(obj.disp_count_handover,'top');
      set(obj.disp_simulation_time_left,'String',int2str(obj.simulation_time_left));
      set(obj.disp_count_handover,'String',int2str(obj.count_handover));
      set(obj.disp_count_disconnection,'String',int2str(obj.count_disconnection));
      plot( [ obj.MD_tmp( : ).x ], [ obj.MD_tmp( : ).y ], 'rx' );
      hold on;
      axis( [ -1300 1300 -1300 1300 ] );
      axis square;
      plot( obj.x_BS, obj.y_BS, '+y' );
      for i = 1:obj.num_BS
        plot( obj.v_x( i, : ), obj.v_y( i, : ), 'b' );
      end
      set( gca, 'Position', [0.15 0.05 1 0.55] );
      hold off;
    end
    
    function obj = pause( obj )
      obj.isPause = true;
    end
      
    function obj = stop( obj )
      obj.isStop = true;
    end
    
    
    function obj = setTemperature( obj, newTemperature )
      obj.temperature = newTemperature + 273.15;
    end
    
    function obj = setBandwidth( obj, newBandwidth )
      obj.bandwidth = newBandwidth * 10^6;
    end
     
    function obj = setPowerBS( obj, newPowerBS )
      obj.power_BS = newPowerBS;
    end
    
    function obj = setPowerMD( obj, newPowerMD )
      obj.power_MD = newPowerMD;
    end
    
    function obj = setGainT( obj, newGainT )
      obj.gain_T = newGainT;
    end
    
    function obj = setGainR( obj, newGainR )
      obj.gain_R = newGainR;
    end

    function obj = setHeightBS( obj, newHeightBS )
      obj.height_BS = newHeightBS;
    end

    function obj = setHeightMD( obj, newHeightMD )
      obj.height_MD = newHeightMD;
    end
    
    function obj = setNumMD( obj, newNumMD )
      obj.num_MD = newNumMD;
    end
    
    function obj = setSimulationTime( obj, newSimulationTime )
      obj.simulation_time = newSimulationTime;
    end

    function obj = setLink( obj, newLinkIndex )
      if newLinkIndex == 1
        obj.link = obj.UP;
      elseif newLinkIndex == 2
        obj.link = obj.DOWN;
      end
      disp( obj.link );
    end
    
    function obj = setHandoverPolicy( obj, newPolicyIndex )
      switch(newPolicyIndex)
        case 1
          obj.handover_policy = obj.EAGER;
        case 2
          obj.handover_policy = obj.LAZY;
        case 3
          obj.handover_policy = obj.THRESHOLD;
        case 4
          obj.handover_policy = obj.HARD_THRESHOLD;
      end
    end
    
    function obj = setPathLossModel( obj, newModelIndex )
      switch(newModelIndex)
        case 1
          obj.path_loss_model = obj.TWORAY;
        case 2
          obj.path_loss_model = obj.SMOOTH;
        case 3
          obj.path_loss_model = obj.COST231;
      end
    end
    
    function obj = applyFading( obj, newFadingOrNot )
      switch( newFadingOrNot )
        case 1
          obj.fadingOrNot = false;
        case 2
          obj.fadingOrNot = true;
      end
    end
    
    function obj = setFadingS( obj, newS )
      obj.s_fading = newS;
    end
    
    function obj = setFadingDeviation( obj, newSigma )
      obj.sigma_fading = newSigma;
    end
    
    function obj = setShadowingDeviation( obj, newSigma )
      obj.sigma_shadowing = newSigma;
    end
    
    function obj = setMeasureInterval( obj, newMinterval )
      obj.measureInterval = newMinterval;
    end
    
    function obj = setMobilitySpeedMean( obj, newSpeed )
      obj.speed = newSpeed;
    end
    
  end
    
end