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
    pass_loss_model
    
    % Positions of BSs
    boundary_x
    boundary_y
    v_x
    v_y
    
    % Mobile Devices
    MD = MobileDevice( 0, 0, 0 );
    MD_tmp = MobileDevice( 0, 0, 0 )
    
    % Model Parameters
    count_handover
    isStop
    isPause
    
  end
  
  properties( Constant )
    % Handover Policy
    EAGER                = 'Instantaneous';
    LAZY                 = 'For a Period';
    THRESHOLD            = 'Threshold: SINR';
    
    % Path-loss Model
    TWORAY               = 'Two-ray model';
    SMOOTH               = 'Smooth Transition model';
    COST231              = 'COST-231 model';
    
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
      obj.num_MD               = 100;
      obj.num_BS               = 19;
      obj.simulation_time      = 900;
      obj.handover_policy      = obj.EAGER;
      obj.pass_loss_model      = obj.TWORAY;

      % Model Parameters
      obj.isStop                = true;
      obj.isPause               = false;
      
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
          obj.MD( count ) = MobileDevice( id_BS, x_temp, y_temp );
          count = count + 1;
        end
      end
      
      obj.simulation_time_left = obj.simulation_time;
      obj.MD_tmp = obj.MD;
      obj.count_handover = 0;
      
      obj.render()
      pause(1)
      
    end
    
    function obj = start( obj, ~, ~ )
      
      if obj.isStop == true
        obj.MD_tmp = obj.MD;
        obj.simulation_time_left = obj.simulation_time;
        obj.count_handover = 0;
        obj.isStop = false;
        obj.render();
      end
      obj.isPause = false;
      
      noise = thermal_noise_power( obj.temperature, obj.bandwidth );
      
      while obj.simulation_time_left > 0
        
        if obj.isStop == true
          break
        elseif obj.isPause == true
          break
        end
        
        obj.simulation_time_left = obj.simulation_time_left - 1;

        % compute BSs' SINR
        distance = ( ( obj.x_BS.' - [ obj.MD_tmp.x ] ) .^ 2 + ( obj.y_BS.' - [ obj.MD_tmp.y ] ) .^ 2 ) .^ 0.5;
        received_power = dBm_2_dB( obj.power_MD ) ...
                         + watt_2_dB( two_ray_ground_model( obj.height_BS, obj.height_MD, distance ) ) ...
                         + obj.gain_T + obj.gain_R;
        received_power_sum = sum( dB_2_watt( received_power ), 2 );
        interference = received_power_sum( [ obj.MD_tmp.id_BS ] ).' - dB_2_watt( received_power );
        sinr = SINR( received_power, interference, noise );

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
              end
            end
          end
        else
          for j = 1:obj.num_MD
            [ maxSINR, maxBS ] = max( sinr( :, j ) );
            if maxBS ~= obj.MD_tmp( j ).id_BS
              if maxSINR > 1
                obj.MD_tmp( j ).id_BS = maxBS;
                obj.count_handover = obj.count_handover + 1;
              end
            end
          end
        end

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
        pause( 1 )
        
      end
      
    end
    
    function obj = initialize( obj, ~, ~ )

      count = 1;
      obj.MD = [];
      while count <= obj.num_MD
        id_BS = randi( obj.num_BS );
        x_temp = obj.R - 2 * obj.R * rand + obj.x_BS( id_BS );
        y_temp = obj.R - 2 * obj.R * rand + obj.y_BS( id_BS );
        if inpolygon( x_temp, y_temp, obj.v_x( id_BS, : ), obj.v_y( id_BS, : ) ) == 1
          obj.MD( count ) = MobileDevice( id_BS, x_temp, y_temp );
          count = count + 1;
        end
      end
      
      obj.simulation_time_left = obj.simulation_time;
      obj.MD_tmp = obj.MD;
      obj.count_handover = 0;
      
      obj.render()
      
    end
    
    function obj = render( obj, ~, ~ )
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
    
    function obj = pause( obj, ~, ~ )
      obj.isPause = true;
    end
      
    function obj = stop( obj, ~, ~ )
      obj.isStop = true;
    end
    
  end
    
end