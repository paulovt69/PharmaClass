PHARMACLASS 3.0 — arquivos para hospedagem

ESTRUTURA
- index.html: página inicial pronta para hospedagem estática
- html/index.html: cópia organizada da interface
- css/styles.css: estilos responsivos
- js/app.js: lógica da plataforma
- PharmaClass_supabase_setup.sql: tabelas, políticas RLS e aula de exemplo

ANTES DE HOSPEDAR
1. Crie um projeto Supabase em https://supabase.com/.
2. No SQL Editor, execute o arquivo PharmaClass_supabase_setup.sql.
3. Em Authentication > URL Configuration, defina o domínio do site publicado como Site URL e adicione URLs de redirecionamento necessárias.
4. Copie a Project URL e a chave publishable (ou anon pública legada) do painel do Supabase.
5. Cole esses valores em SUPABASE_URL e SUPABASE_ANON_KEY no início de js/app.js. Não use service_role/secret key no navegador.
6. Publique a raiz da pasta PharmaClass_3_0 em um host estático HTTPS (por exemplo, Netlify). O arquivo index.html da raiz já aponta para css/styles.css e js/app.js.

PERMISSÕES
- Cadastros públicos viram alunos automaticamente.
- Para autorizar professor, confirme a identidade e execute o UPDATE comentado no SQL.
- RLS protege aulas e progresso no banco; a interface não é a única barreira.

O QUE SINCRONIZA
- Aulas e textos/slides são salvos na tabela lessons e compartilhados.
- Progresso de slides é salvo em student_progress, separado por usuário e aula.
- Links de videoaulas do YouTube ficam no conteúdo da aula e são compartilhados.

LIMITAÇÃO DE MÍDIA
- Imagens enviadas como arquivo e vídeos enviados como arquivo ainda usam armazenamento local e não são compartilhados entre dispositivos. Use links do YouTube para videoaulas compartilhadas até configurar Supabase Storage para arquivos. Não suba vídeos grandes como JSON no banco.
- O histórico da calculadora continua local neste pacote.

SEGURANÇA E TESTES
- Teste com uma conta de aluno e uma conta de professor autorizada.
- Confira que o aluno não consegue editar/publicar aulas e que dois alunos não veem o progresso um do outro.
- Faça a revisão com um professor/responsável técnico da escola antes de inserir dados reais de estudantes.
