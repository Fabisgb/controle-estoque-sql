-- ==============================================================================
-- PROJETO: Modelagem Relacional para Controle de Estoque & Giro (WMS)
-- AUTORA: Fabiana Silva Guimarães
-- DESCRIÇÃO: Estrutura normalizada em MySQL para rastreabilidade de entradas e
--            saídas, cálculo de ponto de pedido e análise de Curva ABC.
-- ==============================================================================

-- 1. CRIAÇÃO DO BANCO DE DADOS
CREATE DATABASE IF NOT EXISTS wms_controle_estoque
DEFAULT CHARACTER SET utf8mb4
DEFAULT COLLATE utf8mb4_unicode_ci;

USE wms_controle_estoque;

-- ==============================================================================
-- 2. DEFINIÇÃO DAS TABELAS (DDL)
-- ==============================================================================

-- Tabela de Fornecedores
CREATE TABLE fornecedores (
    id_fornecedor INT AUTO_INCREMENT PRIMARY KEY,
    razao_social VARCHAR(120) NOT NULL,
    cnpj VARCHAR(18) UNIQUE NOT NULL,
    prazo_entrega_dias INT NOT NULL DEFAULT 5,
    contato_email VARCHAR(100),
    ativo BOOLEAN DEFAULT TRUE
);

-- Tabela de Categorias de Produtos
CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nome_categoria VARCHAR(60) NOT NULL UNIQUE,
    descricao VARCHAR(200)
);

-- Tabela Principal de Produtos (SKUs)
CREATE TABLE produtos (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(20) UNIQUE NOT NULL,
    nome_produto VARCHAR(120) NOT NULL,
    id_categoria INT NOT NULL,
    id_fornecedor INT NOT NULL,
    preco_custo DECIMAL(10, 2) NOT NULL,
    preco_venda DECIMAL(10, 2) NOT NULL,
    estoque_atual INT NOT NULL DEFAULT 0,
    estoque_minimo INT NOT NULL DEFAULT 10,
    ponto_pedido INT NOT NULL DEFAULT 15,
    localizacao_corredor VARCHAR(20),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_produto_categoria FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
    CONSTRAINT fk_produto_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedores(id_fornecedor)
);

-- Tabela de Movimentações de Estoque (Entradas e Saídas)
CREATE TABLE movimentacoes_estoque (
    id_movimentacao INT AUTO_INCREMENT PRIMARY KEY,
    id_produto INT NOT NULL,
    tipo_movimentacao ENUM('ENTRADA', 'SAIDA', 'AJUSTE') NOT NULL,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    data_movimentacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    documento_referencia VARCHAR(40), -- Ex: NF-e ou Pedido de Venda
    observacao VARCHAR(255),
    CONSTRAINT fk_mov_produto FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

-- ==============================================================================
-- 3. CARGA DE DADOS INICIAIS PARA TESTES (DML)
-- ==============================================================================

INSERT INTO fornecedores (razao_social, cnpj, prazo_entrega_dias, contato_email) VALUES
('Distribuidora Atlântico Sul Ltda', '12.345.678/0001-90', 3, 'pedidos@atlanticosul.com.br'),
('TechLog Suprimentos Industriais S.A.', '98.765.432/0001-10', 7, 'comercial@techlog.com.br'),
('Cosméticos & Perfumaria Carioca', '45.678.912/0001-55', 4, 'vendas@cariocaperfumes.com.br');

INSERT INTO categorias (nome_categoria, descricao) VALUES
('Periféricos de TI', 'Mouses, teclados, headsets e acessórios de informática'),
('Perfumaria & Cuidados', 'Itens de higiene, dermocosméticos e fragrâncias'),
('Embalagens & Expedição', 'Caixas de papelão, fitas adesivas e etiquetas térmicas');

INSERT INTO produtos (sku, nome_produto, id_categoria, id_fornecedor, preco_custo, preco_venda, estoque_atual, estoque_minimo, ponto_pedido, localizacao_corredor) VALUES
('TI-001', 'Mouse Óptico Sem Fio Ergonomic', 1, 2, 42.00, 89.90, 8, 10, 18, 'A-01-02'),
('TI-002', 'Teclado Mecânico Compacto USB', 1, 2, 115.00, 229.00, 25, 8, 15, 'A-01-04'),
('PF-101', 'Kit Hidratante Corporal 400ml', 2, 3, 28.50, 64.90, 12, 15, 25, 'B-03-01'),
('PF-102', 'Perfume Floral Clássico 100ml', 2, 3, 75.00, 169.90, 40, 10, 20, 'B-03-05'),
('EM-501', 'Rolo Etiqueta Térmica 100x150mm', 3, 1, 18.00, 35.00, 5, 12, 20, 'C-01-01');

INSERT INTO movimentacoes_estoque (id_produto, tipo_movimentacao, quantidade, documento_referencia, observacao) VALUES
(1, 'ENTRADA', 30, 'NF-10452', 'Compra mensal de reposição'),
(1, 'SAIDA', 22, 'PED-8801', 'Saída para loja virtual'),
(3, 'ENTRADA', 40, 'NF-10489', 'Abastecimento sazonal'),
(3, 'SAIDA', 28, 'PED-8815', 'Venda varejo'),
(4, 'SAIDA', 15, 'PED-8820', 'Saída promocional'),
(5, 'SAIDA', 18, 'ORD-302', 'Consumo interno setor expedição');

-- ==============================================================================
-- 4. CONSULTAS ANALÍTICAS DE GESTÃO LOGÍSTICA (DQL)
-- ==============================================================================

-- CONSULTA A: Alerta de Ruptura e Ponto de Pedido (Reposição Urgente)
SELECT 
    p.sku AS SKU,
    p.nome_produto AS Produto,
    p.estoque_atual AS Estoque_Atual,
    p.ponto_pedido AS Ponto_Pedido,
    p.estoque_minimo AS Estoque_Minimo,
    f.razao_social AS Fornecedor,
    f.prazo_entrega_dias AS Lead_Time_Dias,
    CASE 
        WHEN p.estoque_atual <= p.estoque_minimo THEN 'CRÍTICO - Risco de Ruptura'
        WHEN p.estoque_atual <= p.ponto_pedido THEN 'ALERTA - Emitir Pedido de Compra'
        ELSE 'NORMAL - Estoque Saudável'
    END AS Status_Reposicao
FROM produtos p
INNER JOIN fornecedores f ON p.id_fornecedor = f.id_fornecedor
ORDER BY p.estoque_atual ASC;

-- CONSULTA B: Valor Financeiro Imobilizado por Categoria
SELECT 
    c.nome_categoria AS Categoria,
    COUNT(p.id_produto) AS Qtd_SKUs,
    SUM(p.estoque_atual) AS Total_Unidades,
    CONCAT('R$ ', FORMAT(SUM(p.estoque_atual * p.preco_custo), 2, 'de_DE')) AS Capital_Imobilizado_Custo,
    CONCAT('R$ ', FORMAT(SUM(p.estoque_atual * p.preco_venda), 2, 'de_DE')) AS Potencial_Faturamento
FROM produtos p
INNER JOIN categorias c ON p.id_categoria = c.id_categoria
GROUP BY c.nome_categoria
ORDER BY SUM(p.estoque_atual * p.preco_custo) DESC;

-- CONSULTA C: Histórico de Giro (Total de Saídas por Produto)
SELECT 
    p.sku,
    p.nome_produto,
    COALESCE(SUM(CASE WHEN m.tipo_movimentacao = 'SAIDA' THEN m.quantidade ELSE 0 END), 0) AS Total_Saidas,
    p.estoque_atual AS Saldo_Disponivel,
    p.localizacao_corredor AS Endereco_WMS
FROM produtos p
LEFT JOIN movimentacoes_estoque m ON p.id_produto = m.id_produto
GROUP BY p.id_produto, p.sku, p.nome_produto, p.estoque_atual, p.localizacao_corredor
ORDER BY Total_Saidas DESC;
