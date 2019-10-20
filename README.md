# meetup-DevOps

## Criando um playbook para instalar e configurar o uwsgi e nginx

### Colocando chave ssh no servidor
* Antes de mais nada, precisamos ter nossa chave ssh no servidor para não termos que ficar digitando a senha a cada vez que formos rodar o playbook
* Para pegar a sua chave de um cat no arquivo ~/.ssh/id_rsa.pub

  `$ cat /.ssh/id_rsa.pub`
 
* Adicione sua chave na máquina remota no arquivo /root/.ssh/authorized_keys
 
  `$ vim /root/.ssh/authorized_keys`
  
 ### Instalando o ansible
* É necessário instalar o ansible nas máquinas do laboratório, faremos isso com o pip
 
  `$ pip3 install ansible`
 
### Criando nosso arquivo de inventory
* Vamos criar nosso inventory e colocar nosso host
  
  `$ vim inventory.yml`
  ```
  all:
  vars:
    ansible_user: root
    ansible_python_interpreter: /usr/bin/python3

  hosts:
    192.168.56.101:
  ```
  
  ### Iniciando nossa role de configura o uwsgi com o ansible-galaxy
  * Utilizaremos o ansible-galaxy para criar a estrutura da nossa role
  
  `$ ansible-galasy init uwsgi`
 
 ```
  uwsgi
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── README.md
├── tasks
│   └── main.yml
├── templates
│   └── nginx.j2
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml

8 directories, 9 files

  ```
* Após executar o comando teremos um estrutura de arquivos como a mostrara acima

### Criando task para instalar as dependências
* Vamos criar um play que vai instalar o pocotes necessários com o apt

`$ vim uwsgi/tasks/main.yml`
```
- name: install prerequisites (apt)
  apt:
    name: "{{ apt_packages }}"
    state: present
```
  
* Agora precisamos declarar os pacotes que serão instalados. Edite o arquivo uwsgi/vars/main.yml
  ```
  apt_packages:
    - build-essential
    - python3-setuptools 
    - libssl-dev
    - uwsgi
    - python3-pip 
    - python3-dev
    - uwsgi-plugin-python
  ```
### Instalando pacotes pip
* Edite novamente o arquivo uwsgi/tasks/main.yml
  ```
  - name: ensure flask is present
  pip:
    name: "{{ pip_packages }}"
    state: present
    executable: pip3
  ```
* E adicione os pacotes em uwsgi/vars/main.yml
  ```
  pip_packages:
  - wheel
  - flask
  ```
### Criando um template para o arquivo de configuração do uwsgi
* É uma boa prática utilizar templates para arquivos de configuração. Garanto que sempre que eu rodar o playbook, independemente do host,eu terei o mesmo resultado.
* Criar um arquivo uwsgi.ini.j2 em uwsgi/templates/ com o seguinte conteúdo.
  ```
  [uwsgi]
  module = wsgi:app
  socket = 0.0.0.0:5000
  protocol = http
  chmod-socket = 660

  master = true
  processes = {{ uwsgi_conf.processes }}

  chdir: /root/project

  socket = myproject.sock
  chmod-socket = 660
  vacuum = true

  die-on-term = true

  enable-threads = {{ uwsgi_conf.enabled_threads }}
  threads = {{ uwsgi_conf.threads }}
  uid = root
  gid = root
  logto = /var/log/uwsgi/app/uwsgi.log

  ```
* Declarar as variáveis que serão usadas no template no arquivo uwsgi/defaults/main.yml.
  ```
  uwsgi_conf:
    enabled_threads: true
    processes: 2
    threads: 4

  more_uwsgi_conf:
    harakiri: 30
    reload-on-rss: 500

  ```
* Criar o play para enviar esse arquivo do template para o servidor:
  ```
  - name: ensure file of configuration uwsgi is present
  template:
    src: templates/uwsgi.ini.j2
    dest: /etc/uwsgi/apps-enabled/uwsgi.ini
  ```
  
### Copiando o arquivo com o app flask
* Vamos enviar um app em flask, que utilizaremos para testar nosssa configuração do uwsgi. Salvar o aruivo project.py e wsgi.py que estão nesse repositório em uwsgi/files/
* Abaixo o play que envia o arquivo para o servidor.
  ```
  - name: Copy flask project to {{ansible_hostname}}
  copy:
    src: files/{{item}}
    dest: /root/
  with_items:
    - project.py
    - wsgi.py

  ```
### Copiando o arquivo do systemd que será utilizado para start/stop/restart do uwsgi
* No repositório tem um arquivo chamado project.service que deve ser salvo em uwsgi/files/
* O play abaixo envia o arquivo para o servidor\
  ```
  - name: copy systemd file
  copy:
    src: files/project.service
    dest: /etc/systemd/system/

  ```
* Habilitar o arquivo de systemd e startar o uwsgi.
  ```
  - name: Start uwsgi with systemd
  systemd:
    name: project.service
    enabled: yes
    state: started
    daemon-reload: yes
  ```
### Utilizando o mod ini_files (apenas demostrativo)
* Utilizando o module ini_file para adicionar algumas informações a mais no arquivo de configuração do uwsgi.
  ```
  - name: add harakiri and max memory usage on uwsgi conf
  ini_file:
    path: /etc/uwsgi/apps-enabled/uwsgi.ini
    section: uwsgi
    option: "{{ item.key }}"
    value: "{{ item.value }}"
  loop: "{{ more_uwsgi_conf | dict2items }}"
  notify: restart uwsgi

  ```

