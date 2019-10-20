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
  
