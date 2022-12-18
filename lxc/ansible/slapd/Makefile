HOSTS = hosts
SITE_YML = site.yml

all :
	ansible-playbook -i $(HOSTS) $(SITE_YML)

list :
	ansible-playbook -i $(HOSTS) --list-tags $(SITE_YML)

% :
	ansible-playbook -i $(HOSTS) --tags $@ $(SITE_YML)

