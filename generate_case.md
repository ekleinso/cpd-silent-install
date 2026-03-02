Download case files and create tar
```shell
mkdir -p ~/cp4d530
cd ~/cp4d530
git clone -b v530 https://github.com/ekleinso/cpd-silent-install.git

export ALL_COMPONENTS="cpfs,cpd_platform,ibm-licensing,scheduler,factsheet,analyticsengine,cognos_analytics,dashboard,datagate,dp,dataproduct,datarefinery,replication,datastage_ent,datastage_ent_plus,dv,db2oltp,bigsql,dmc,db2wh,dods,edb_cp4d,postgresql,hee,wkc,ikc_premium,ikc_standard,datalineage,match360,streamsets,informix_cp4d,informix,mantaflow,mongodb,mongodb_cp4d,openpages,ws_pipelines,planning_analytics,productmaster,rstudio,spss,syntheticdata,voice_gateway,watson_discovery,wml,openscale,watson_speech,ws,ws_runtimes,watsonx_ai,watson_assistant,wca,wca_ansible,wca_z,wca_z_ce,watsonx_data,watsonx_governance,watsonx_orchestrate"
export VERSION="5.3.0"

cpd-cli manage case-download \
--components=${ALL_COMPONENTS} \
--release=${VERSION}

cd cpd-cli-workspace/olm-utils-workspace/work
sudo tar cvf cpd-5.3.0-offline-case.tar offline
sudo gzip cpd-5.3.0-offline-case.tar
sudo mv cpd-5.3.0-offline-case.tar.gz ../../../cpd-alt-install
```

Create case yaml files

```shell
mkdir work
cd work
cp cpd-5.3.0-offline-case.tar.gz
split -d -b 1000000 cpd-5.3.0-offline-case.tar.gz case-

cd ..
for i in `ls work/case-*`
do 
  filename=$(echo $i | cut -f 2 -d /)
  oc create secret generic $filename --from-file=$filename=work/$filename --dry-run=client -o yaml > $filename.yaml
done
```
