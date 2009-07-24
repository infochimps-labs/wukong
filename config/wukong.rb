# ---------------------------------------------------------------------------
#
# Configuration options for Wukong
#   http://github.com/infochimps/wukong
#
# !! Don't edit this file !!
# Instead, create a new file wukong-site.rb and set your options there
#

# ---------------------------------------------------------------------------
#
# Script options
#

Wukong::CONFIG.merge!({
    #
    # Path to root of hadoop install. If your hadoop runner is
    #
    #   /usr/local/share/hadoop/bin/hadoop
    #
    # then your hadoop_home is
    #
    #   /usr/local/share/hadoop.
    #
    # You should set this in the config/wukong-site.rb file
    #
    :hadoop_home =>  "/usr/local/share/hadoop",

    # Run as local or as hadoop?
    :default_run_mode => 'hadoop',

    # The command to run when a nil mapper or reducer is given.
    :default_mapper   => '/bin/cat',
    :default_reducer  => '/bin/cat',

    # Anything in HADOOP_OPTIONS_MAP (see lib/wukong/script/hadoop_command.rb)
    :runner_defaults => {
    },
  })
