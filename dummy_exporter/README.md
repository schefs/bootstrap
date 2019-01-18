# Dummy Exporter

This is a prometheus fake exporter generating fake metrics just for educational purposes.

## Build locally

    $ docker build -t my_dummy_exporter:latest .
    $ docker run -d -p 65433:65433 --name my_dummy_exporter schefs/my_dummy_exporter

## You can also run a image strait from docker hub

    $ docker run -d -p 65433:65433 --name my_dummy_exporter schefs/my_dummy_exporter:stable

- Then you can curl `http://localhost:65433` to make sure everything works.

## kubernetes deployment

    $ kubectl apply -f dummy_exporter.yaml
