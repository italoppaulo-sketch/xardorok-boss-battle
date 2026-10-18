# Origem e condições de uso

Registro consultado em **18/10/2026**. Os áudios são saídas novas solicitadas para Xardorok Boss Battle por texto, sem enviar músicas, melodias ou samples de terceiros como referência sonora.

| Recursos | Origem | Identificação |
| --- | --- | --- |
| Música | Geração instrumental pelo serviço Runway, modelo Lyria 3 Pro | Task `39a0171f-0991-4df6-bf3e-b606150a5e7c` |
| Cinco efeitos | Cinco gerações independentes pelo serviço Runway Sound Effects | IDs em `sources/provenance.json` |
| Edições | FFmpeg local | Receita reproduzível em `sources/prepare_audio.py` |
| Personagens, jogo e nomes | Projeto existente do usuário | Nenhum arquivo visual ou mecânico alterado |

## Possibilidade de uso no jogo

A página oficial de direitos de uso do Runway informa que suas gerações podem ser utilizadas comercialmente, sem uma restrição não comercial imposta pelo serviço. Os termos, seção 4.4, dizem que a empresa não reivindica propriedade dos inputs/outputs e não restringe o uso comercial dos outputs, condicionado ao cumprimento do contrato. Isso permite considerar estas saídas para uso no jogo, observadas essas condições.

Fontes oficiais consultadas:

- [Uso comercial](https://help.runwayml.com/hc/en-us/articles/21668707517587-Can-I-use-the-content-I-made-in-Runway-for-commercial-purposes)
- [Terms of Use, atualização de 15/09/2026, seções 4.2–4.4](https://runway.com/terms-ofuse)
- [Usage Policy](https://runway.com/safety/usage-policy)

Esta documentação registra as condições gerais publicadas pelo fornecedor; não é um certificado individual de exclusividade. Não atribui licença CC0, domínio público nem uma licença aberta nova aos áudios. O fato de o arquivo estar em um repositório público não substitui suas condições de uso.

Não foram utilizadas gravações de Chrono Trigger, Final Fantasy VI ou de outro jogo. Não foi feita busca exaustiva de similaridade contra catálogos, e a geração por IA não permite prometer ausência absoluta de coincidências, exclusividade ou proteção autoral em todas as jurisdições. Não há MIDI, partitura ou stems instrumentais fornecidos pelo serviço que permitam atestar todas as notas da composição. A escolha artística e a autorização de integração desta proposta continuam pendentes do usuário.

Não há reprodução da API do Runway dentro do jogo, autenticação, consulta remota ou geração em tempo de execução: são somente arquivos de áudio estáticos para avaliação. As regras específicas de quem integra a API em seu produto são distintas deste pacote de arquivos.
