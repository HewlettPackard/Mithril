# Jenkins pipeline

## How to set up and use Vault secrets in a Jenkins pipeline

### Setting up your Vault secrets

- Install [HashiCorp Vault](https://www.vaultproject.io/downloads) in your 
system. This will add the Vault CLI that we will use to access the secrets store.
- Create a [GitHub token](https://github.hpe.com/Vault/Wiki/wiki/Onboarding#generate-a-github-token-for-accessing-vault-via-jenkins-pipeline-ui-andor-cli) using your HPE GitHub user. Save it in a safe place.
- Set your `VAULT_ADDR` pointing to HPE's Vault server:
```bash
export VAULT_ADDR=https://vault.docker.hpecorp.net:443
```
Please note that from now on, you must be connected to the HPE VPN to have access to the Vault server.
- Login to the Vault server using your newly created GitHub token:
```bash
vault login -method=github token=<YOUR GITHUB TOKEN HERE>
```
- Check that you have access to your organization's secrets path:
```bash
vault read secret/hpe4it-jenkins-ci/repo/sec-eng/istio-spire
```
That should output a list of the secrets stored in the Jenkins path (if any), or a permission denied error if you don't have access to it.

If you don't have permissions, make sure to add yourself or have someone else  add you to the [`sec-eng` org team](https://github.hpe.com/orgs/Docker-in-Datacenter-VaultTeams/teams/sec-eng/members). Read [step #2 here](https://github.hpe.com/Vault/Wiki/wiki/Onboarding#onboarding) for more information.


- Now you can store as many secrets as you want in the Jenkins' path, but **be aware that writing to a specific path will overwrite all the existing secrets in the same path**. If you don't want to lose the existing secrets, you can create your custom sub-path (something like `secret/hpe4it-jenkins-ci/repo/sec-eng/istio-spire/mysubpath`) or make sure you re-write the existing secrets along with the new ones you need.

- Set up the secret(s) you need (**run this only if you want to reset all the secrets in the root path**):
```bash
vault write secret/hpe4it-jenkins-ci/repo/sec-eng/istio-spire \
    mySuperSecret=myt0k3n \
    mySecondSecret=2ndt0k3n
```

### Accessing the secrets from the Jenkins pipeline

HPE's Jenkins has a convenience helper function for reading Vault secrets.

```groovy
pipeline {
    # ...
    script {
        secrets = vaultGetSecrets()
        print secrets.mySuperSecret
        print secrets.mySecondSecret
    }
}
```


Please refer to the [HPE Vault wiki](https://github.hpe.com/Vault/Wiki/wiki/Onboarding) for more information.
