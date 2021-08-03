# Mithril Demo

This is a Demo of the Mithril Project.

The script will setup all the configuration to deploy `Mithril` followed by the deploy of the `Bookinfo` application example and a quick demonstration of `SPIRE` issuing identites.

This Demo requires **a running kubernetes cluster** and the **AWS CLI fully configured**. you can check how to configure the AWS CLI [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

To run it, just execute the shell script:
```bash
./demo-script.sh
```
In order to see the SPIRE logs (both `agent` and `workload`) you can use the following command:

```bash
tail -n 1000 $HOME/mithril/spire/spire.log
```
and
```bash
tail -n 1000 $HOME/mithril/spire/workload.log
```

You can also see the live logs using this command:
```bash
watch kubectl logs $(kubectl get pod -l app=details -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
```
and

```bash
watch kubectl logs $(kubectl get pod -l app=spire-agent -o jsonpath='{.items[0].metadata.name}' -n spire) -n spire
```