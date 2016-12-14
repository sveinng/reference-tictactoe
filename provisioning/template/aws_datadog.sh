echo "*** Install Datadog monitor agent"
DD_API_KEY=541d9973f1d76fdc58142c0a03c97e6b bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/install_agent.sh)"
usermod -a -G docker dd-agent

cat <<EOF > /etc/dd-agent/conf.d/docker_daemon.yaml
init_config:

instances:
  - ## Daemon and system configuration
    url: "unix://var/run/docker.sock"
EOF

cat <<EOF > /etc/dd-agent/conf.d/http_check.yaml
init_config:
instances:
  - name: TicTacToe-PROD
    url: http://localhost
    timeout: 1
    content_match: 'React'
    skip_event: true
EOF

/etc/init.d/datadog-agent restart

echo "*** Datadog done!"

