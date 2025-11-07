# Flair 

## 1 Build the Image

In the folder where your **Dockerfile** is located, run:

```bash
docker build -t flair-dev -f Dockerfile.hacks .
```

## 2 Run the Container

> [!NOTE] Windows users
> If you are on Windows, run this Docker command in a **WSL2 distribution** with **WSLg enabled** (on by default in WSL settings) and integrated with [Docker Desktop](https://docs.docker.com/desktop/features/wsl/#enabling-docker-support-in-wsl-2-distributions)

After building, start the container:

```bash
docker run -it -d --name flair-dev --privileged --env DISPLAY=$DISPLAY --volume /tmp/.X11-unix:/tmp/.X11-unix:rw flair-dev
```

## 3 Access the Container

Enter the running container:

```bash
docker exec -it flair-dev /bin/bash
```

## 4 Allow GUI Apps (on Host)

Run this **on your host machine** to allow GUI apps from the container:

```bash
xhost +SI:localuser:root
```

## 5 Open in VS Code with Dev Containers Extension

You can open and work directly inside the running container using VS Code’s **Dev Containers** extension:

1. **Install the Dev Containers extension**
   In VS Code, go to **Extensions (`Ctrl+Shift+X`)** → search for **“Dev Containers”** by Microsoft → install it.

2. **Attach to the running container**
   Press `F1` → type **“Dev Containers: Attach to Running Container…”** → select **`flair-dev`** from the list.

3. **Start coding inside the container**
   VS Code will open a new window connected to your container environment.
   You’ll have full terminal, IntelliSense, and extension support inside the container.
