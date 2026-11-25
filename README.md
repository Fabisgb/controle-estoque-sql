📦 Modelagem Relacional para Controle de Estoque & Giro (WMS)

Projeto de modelagem de banco de dados relacional em MySQL voltado à gestão logística de armazenagem, controle de inventário e prevenção de rupturas de estoque.

🎯 Problema & Objetivo

Em operações de varejo e centros de distribuição, a falta de visibilidade sobre o giro de mercadorias gera dois gargalos críticos: ruptura de estoque (perda de vendas por falta de produto) e excesso de capital imobilizado em itens de baixa saída.

Este projeto estrutura uma base normalizada capaz de rastrear entradas e saídas, calcular automaticamente o status de reposição com base no lead time dos fornecedores e gerar indicadores financeiros por categoria.

🗂️ Estrutura do Banco de Dados (Modelo Relacional)

O esquema (estoque_giro_wms.sql) é composto por quatro entidades principais interligadas por chaves estrangeiras (FOREIGN KEY):

fornecedores: Cadastro de parceiros comerciais e prazos médios de entrega (lead time).

categorias: Agrupamento lógico dos produtos para análises financeiras e de giro.

produtos: Cadastro de SKUs contendo custos, preços de venda, estoque mínimo, ponto de pedido e endereçamento físico no armazém (corredor/prateleira).

movimentacoes_estoque: Histórico auditável de todas as operações (ENTRADA, SAIDA, AJUSTE) vinculadas a documentos fiscais ou pedidos.

📊 Consultas Analíticas Implementadas

O script já inclui carga de dados fictícios e três consultas prontas para tomada de decisão:

Alerta de Ruptura e Ponto de Pedido: Cruza o saldo atual com o estoque mínimo e o ponto de pedido, sinalizando visualmente quais itens exigem emissão imediata de ordem de compra.

Capital Imobilizado por Categoria: Calcula o valor total em estoque a preço de custo e o potencial de faturamento por linha de produto.

Ranking de Giro por SKU: Soma o volume de saídas por item e exibe seu endereçamento físico no WMS para otimizar o picking (separação de pedidos).

🚀 Como Executar

Clone ou baixe o arquivo estoque_giro_wms.sql.

Abra-o em seu cliente MySQL de preferência (MySQL Workbench, DBeaver ou terminal).

Execute o script completo para criar o banco wms_controle_estoque, popular as tabelas e visualizar os relatórios.

👩‍💻 Autora

Desenvolvido por Fabiana Silva Guimarães — Estudante de Ciência da Computação e Técnica em Logística.

🔗 Portfólio Completo | LinkedIn
