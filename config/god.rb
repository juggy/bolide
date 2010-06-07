# run with: god -c /path/to/mongrel.god -D
# 
# This is the actual config file used to keep the mongrels of
# gravatar.com running.

pids = {
  'bfeature'=>'/u/apps/bolide/shared/pids/unicorn.pid',
  'bstream'=>'/u/apps/bolide/shared/pids/live.unicorn.pid',
  'bhost'=>'/u/apps/bolide/current/helpers/vhost/bhost.pid',
  'bstat'=>'/u/apps/bolide/current/helpers/statistics/bstat.pid'
}

pids.each do |name, pid_path|
  God.watch do |w|   
    w.name = name
    w.group = 'bdaemons'
    w.interval = 30.seconds
  
    w.start = "/etc/init.d/#{name} start"
    w.start_grace = 10.seconds
  
    w.stop = "/etc/init.d/#{name} stop"
    w.stop_grace = 10.seconds
  
    w.restart = "/etc/init.d/#{name} restart"

    w.pid_file = pid_path
  
    w.behavior(:clean_pid_file)

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end

    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above = 150.megabytes
        c.times = [3,5] # 3 out of 5 intervals
      end

      restart.condition(:cpu_usage) do |c|
        c.above = 50.percent
        c.times = 5
      end
    end

    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart]
        c.times = 5
        c.within = 5.minutes
        c.transition = :unmonitored
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hours
      end
    end
  end
end
