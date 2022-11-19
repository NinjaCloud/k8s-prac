echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >>  ~/.bashrc_aliases
source ~/.bashrc ~/.bashrc_aliases
complete -F __start_kubectl k
