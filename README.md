# Practica 5

## Inicializacion del Proyecto

El proyecto se basa en usar Vagrant, con el cual administramos y podemos crear varias maquinas virtuales en nuestra interfaz de VirtualBox. Para esto, lo que necesitamos primero es tener el archivo que nos proporciona el profesor y entrar a este mediante nuestro VS Code para que sea mas comodo.

Una vez ahi, modificaremos el `Vagrantfile` para ponerle nuestro numero de red en clase y realizamos el primer comando para levantar todas las maquinas: **`vagrant up`**. Este comando comenzara a levantar todas nuestras maquinas, lo cual llevara un tiempo. Si todo sale bien, podremos ver como en nuestra interfaz de VirtualBox se nos ha creado un nuevo grupo y tenemos varias maquinas corriendo.

## Firewall 

Seguimos con la parte importante de nuestro firewall. Aquí tenemos definido todo lo necesario con todas las reglas en **iptables**, con los ajustes que nos han ido pidiendo poco a poco para ajustarlo y hacerlo a medida.

Si queremos ejecutarlo de forma manual, lo que tendremos que hacer sera acceder a la maquina gw mediante ssh con el comando **`vagrant ssh gw`**, ya que esta sera la que contenga el script. Una vez dentro, simplemente localizamos el archivo y lo ejecutamos para que se apliquen las reglas al momento.

---

## Instrucciones de Uso

Para que cualquiera pueda ponerse a usar este entorno rápidamente, solo hay que seguir estos pasos:

1.  Hacemos un **git clone** de este repositorio para bajarnos todo.
2.  Entramos en la carpeta donde está el `Vagrantfile`.
3.  Ejecutamos **`vagrant up`** y esperamos a que monten las máquinas.
4.  Cuando terminemos de trabajar, cerramos todo ordenadamente con **`vagrant halt`**.

## Minichuleta de Vagrant

Aquí dejo los comandos básicos para no perderse:

* **`vagrant up`**: Levanta y arranca las máquinas virtuales (crea el entorno).
* **`vagrant halt`**: Apaga las máquinas de forma segura (como darle al botón de apagar).
* **`vagrant reload`**: Reinicia las máquinas (muy útil si cambiamos algo en el Vagrantfile y queremos recargar la config).
* **`vagrant destroy`**: Elimina todo por completo (borra las máquinas virtuales y discos).
* **`vagrant ssh [nombre]`**: Para entrar dentro de una máquina concreta (ej: `vagrant ssh gw`).