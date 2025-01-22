## Post-Deployment Guide for Elasticsearch and Kibana

## 1. Reset Kibana System Password in Elasticsearch

To reset the `kibana_system` user password, run the following command:

```bash
kubectl -n elasticsearch exec -ti pod/<elasticsearch-pod-name> -- bin/elasticsearch-reset-password -u kibana_system
```

Replace `<elasticsearch-pod-name>` with the actual pod name.

---

## 2. Encode the New Password

Once the new password is generated, encode it using Base64:

```bash
echo <your-new-password> | base64
```

Replace `<your-new-password>` with the generated password.

---

## 3. Update Kibana Credentials

Edit the secret containing Kibana credentials to update it with the new password:

```bash
kubectl -n kibana edit secret logging-nebulous-logging-mechanism-credentials
```

Locate the relevant key (e.g., `kibana-password`) and replace its value with the new Base64-encoded password.

---

## 4. Restart Kibana Deployment

After updating the credentials, restart the Kibana deployment to apply the changes:

```bash
kubectl rollout restart deployment kibana -n kibana
```

---

## 5. (Optional) Expose Kibana Using NodePort

If external access to Kibana is required, expose the deployment as a NodePort service:

```bash
kubectl expose deployment kibana \
  --type=NodePort \
  --name=kibana-nodeport \
  --port=5601 \
  --target-port=5601 \
  -n kibana
```

---

## 6. Verify the Kibana Service

Check the details of the exposed Kibana service:

```bash
kubectl -n kibana get svc
```

Look for the NodePort assigned and use it to access Kibana via `<node-ip>:<node-port>`.

---

## Notes

- Ensure the namespace is correctly specified when running the commands.
- Use `kubectl get pods -n elasticsearch` and `kubectl get pods -n kibana` to get pod names.
- Monitor logs to verify Kibana is running properly:

  ```bash
  kubectl logs -f deployment/kibana -n kibana
  ```

---

End of guide.
