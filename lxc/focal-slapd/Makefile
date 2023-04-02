HOSTS = hosts
SITE_YML = site.yml

all :
	ansible-playbook -i $(HOSTS) $(SITE_YML)

list :
	ansible-playbook -i $(HOSTS) --list-tags $(SITE_YML)

debug :
	ansible-playbook -i $(HOSTS) -v debug.yml

% :
	ansible-playbook -i $(HOSTS) -v --tags $@ $(SITE_YML)

