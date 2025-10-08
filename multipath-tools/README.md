# multipath-tools

multipath-tools has been tested with a remote multipath target with `multipath` commands run in the mount namespace of the `ext-multipathd` Talos extension service.
TODO: add a test to verify that the multipath-tools are working.

```yaml
# multipathd-config.yaml
---
apiVersion: v1alpha1
kind: ExtensionServiceConfig
name: multipathd
environment:
  - VAR=<your_token>
```

Then apply the patch to your node's MachineConfigs
```bash
talosctl patch mc -p @multipathd-config.yaml
```
