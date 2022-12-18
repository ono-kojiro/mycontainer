all :
	ansible-playbook -i hosts site.yml

list :
	ansible-playbook -i hosts --list-tags site.yml

slapd :
	ansible-playbook -i hosts --tags slapd site.yml

% :
	ansible-playbook -i hosts --tags $@ site.yml

