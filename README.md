# toolbox
Some useful libraries require you to build from source because they don't support `pip`. Others require it if you want GPU support. 

Build
-----
```
$ nvidia-docker build -t toolbox:latest .
$ mkdir data
$ mkdir app
```

Open up a notebook
------------------
```
$ nvidia-docker run --rm \
    --name toolbox \
    -v `pwd`/notebooks:/notebooks \
    -v `pwd`/data:/data \
    -v `pwd`/app:/app \
    -p 8888:8888 \
    toolbox:latest \
    jupyter-notebook --notebook-dir=/notebooks --ip 0.0.0.0 --allow-root --no-browser --allow-root
```
