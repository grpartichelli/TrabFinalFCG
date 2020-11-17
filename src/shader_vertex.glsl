#version 330 core

// Atributos de v�rtice recebidos como entrada ("in") pelo Vertex Shader.
// Veja a fun��o BuildTrianglesAndAddToVirtualScene() em "main.cpp".
layout (location = 0) in vec4 model_coefficients;
layout (location = 1) in vec4 normal_coefficients;
layout (location = 2) in vec2 texture_coefficients;

// Matrizes computadas no c�digo C++ e enviadas para a GPU
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Atributos de v�rtice que ser�o gerados como sa�da ("out") pelo Vertex Shader.
// ** Estes ser�o interpolados pelo rasterizador! ** gerando, assim, valores
// para cada fragmento, os quais ser�o recebidos como entrada pelo Fragment
// Shader. Veja o arquivo "shader_fragment.glsl".
out vec4 position_world;
out vec4 position_model;
out vec4 normal;
out vec2 texcoords;

// Identificador que define qual objeto est� sendo desenhado no momento
#define TROPHY 0
#define FLOOR 1
#define TORRE 2
#define ROBOTTOP 3
#define ROBOTBOTTOM 4
#define CUBE 5
#define SPHERE 6
uniform int object_id;

// Par�metros da axis-aligned bounding box (AABB) do modelo
uniform vec4 bbox_min;
uniform vec4 bbox_max;

// Vari�veis para acesso das imagens de textura
uniform sampler2D TextureOuro;
uniform sampler2D TextureGrama;
uniform sampler2D TextureTijolo;
uniform sampler2D TextureMetalClaro;
uniform sampler2D TextureMetalEscuro;
uniform sampler2D TextureMeteoro;

// O valor de sa�da ("out") de um Fragment Shader � a cor final do fragmento.
out vec3 cor_vertex;

// Constantes
#define M_PI   3.14159265358979323846
#define M_PI_2 1.57079632679489661923

void main()
{
    // A vari�vel gl_Position define a posi��o final de cada v�rtice
    // OBRIGATORIAMENTE em "normalized device coordinates" (NDC), onde cada
    // coeficiente estar� entre -1 e 1 ap�s divis�o por w.
    // Veja {+NDC2+}.
    //
    // O c�digo em "main.cpp" define os v�rtices dos modelos em coordenadas
    // locais de cada modelo (array model_coefficients). Abaixo, utilizamos
    // opera��es de modelagem, defini��o da c�mera, e proje��o, para computar
    // as coordenadas finais em NDC (vari�vel gl_Position). Ap�s a execu��o
    // deste Vertex Shader, a placa de v�deo (GPU) far� a divis�o por W. Veja
    // slides 41-67 e 69-86 do documento Aula_09_Projecoes.pdf.

    gl_Position = projection * view * model * model_coefficients;


    // Agora definimos outros atributos dos v�rtices que ser�o interpolados pelo
    // rasterizador para gerar atributos �nicos para cada fragmento gerado.

    // Posi��o do v�rtice atual no sistema de coordenadas global (World).
    position_world = model * model_coefficients;

    // Posi��o do v�rtice atual no sistema de coordenadas local do modelo.
    position_model = model_coefficients;

    // Normal do v�rtice atual no sistema de coordenadas global (World).
    // Veja slides 123-151 do documento Aula_07_Transformacoes_Geometricas_3D.pdf.
    normal = inverse(transpose(model)) * normal_coefficients;
    normal.w = 0.0;

    // Coordenadas de textura obtidas do arquivo OBJ (se existirem!)
    texcoords = texture_coefficients;

        // Obtemos a posi��o da c�mera utilizando a inversa da matriz que define o
    // sistema de coordenadas da c�mera.
    vec4 origin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 camera_position = inverse(view) * origin;

    // O fragmento atual � coberto por um ponto que percente � superf�cie de um
    // dos objetos virtuais da cena. Este ponto, p, possui uma posi��o no
    // sistema de coordenadas global (World coordinates). Esta posi��o � obtida
    // atrav�s da interpola��o, feita pelo rasterizador, da posi��o de cada
    // v�rtice.
    vec4 p = position_world;

    // Normal do fragmento atual, interpolada pelo rasterizador a partir das
    // normais de cada v�rtice.
    vec4 n = normalize(normal);

    // Vetor que define o sentido da fonte de luz em rela��o ao ponto atual.
    vec4 l = normalize(vec4(1.0,1.0,0.0,0.0));

    // Vetor que define o sentido da c�mera em rela��o ao ponto atual.
    vec4 v = normalize(camera_position - p);

    // Blinn-Phong Illumination
    vec3 I = vec3(1.0, 1.0, 1.0);
    vec3 refletancia_difusa;
    vec4 h;
    float q;
    vec3 blinn_phong_specular_term = vec3(0.0, 0.0, 0.0); //inicializando em 0 para poder calcular somente em alguns objetos
    //BBOX
    float minx = bbox_min.x;
    float maxx = bbox_max.x;

    float miny = bbox_min.y;
    float maxy = bbox_max.y;

    float minz = bbox_min.z;
    float maxz = bbox_max.z;

    // Coordenadas de textura U e V
    float U = (position_model[0] - minx)/(maxx-minx); //Pr� calculando uma proje��o planar
    float V = (position_model[1] - miny)/(maxy-miny); //Pr� calculando uma proje��o planar

    //Pr� calculando a proje��o esf�rica
    vec4 bbox_center   = (bbox_min + bbox_max) / 2;
    vec4 p_vec = bbox_center + ((position_model - bbox_center)/length(position_model - bbox_center));
    float theta = atan(p_vec[0],p_vec[2]);
    float phi = asin(p_vec[1]);


    vec3 Kd0;
    switch(object_id)
    {
        // PROJE��O PLANAR PARA O TROF�U
        case TROPHY:
            //Utilizando a texture de Ouro para o trof�u
            Kd0 = texture(TextureOuro, vec2(U,V)).rgb;

            refletancia_difusa = vec3(0.8,0.8,0.8);
            h = normalize(v + l);
            q = 32.0;
            blinn_phong_specular_term = refletancia_difusa*I*pow(max(0,dot(n,h)), q);

            break;

        case FLOOR:
            //PROJE��O DO CH�O UTILIZANDO UM ESTILO REPEAT
            U = position_model[0];
            U = U -floor(U);
            V = position_model[2];
            V = V - floor(V);
            //Utilizando a textura de grama para o ch�o
            Kd0 = texture(TextureGrama, vec2(U,V)).rgb;
            refletancia_difusa = vec3(0.5,1.0,0.5); // luz esverdeada
            h = normalize(v + l);
            q = 50.0;
            blinn_phong_specular_term = refletancia_difusa*I*pow(max(0,dot(n,h)), q);
            break;
        // PROJE��O PLANAR PARA A TORRE
        case TORRE:
            Kd0 = texture(TextureTijolo, vec2(U,V)).rgb; //Utilizando a textura de tijolo para a torre

            break;

        //PROJE��O PLANAR PARA ROBO
        case ROBOTTOP:
            Kd0 = texture(TextureMetalClaro, vec2(U,V)).rgb; //Utilizando a textura de metal claro para o topo

            refletancia_difusa = vec3(0.8,0.8,0.5);
            h = normalize(v + l);
            q = 10.0;
            blinn_phong_specular_term = refletancia_difusa*I*pow(max(0,dot(n,h)), q);

            break;
        case ROBOTBOTTOM:
            Kd0 = texture(TextureMetalEscuro, vec2(U,V)).rgb;  //Utilizando a textura de metal escuro para a parte de baixo

            refletancia_difusa = vec3(0.8,0.8,0.8);
            h = normalize(v + l);
            q = 32.0;
            blinn_phong_specular_term = refletancia_difusa*I*pow(max(0,dot(n,h)), q);

            break;
        //PROJE��O ESF�RICA PARA A ESFERA
        case SPHERE:
            U = (theta + M_PI)/(2*M_PI);
            V = (phi + M_PI_2)/M_PI;
            Kd0 = texture(TextureTijolo, vec2(U,V)).rgb;

            refletancia_difusa = vec3(0.8,0.8,0.7);
            h = normalize(v + l);
            q = 32.0;
            blinn_phong_specular_term = refletancia_difusa*I*pow(max(0,dot(n,h)), q);

            break;
        ////PROJE��O PLANAR PARA O CUBO
        case CUBE:
            refletancia_difusa = vec3(0.0,0.0,0.0); // luz branca
            h = normalize(v + l);
            q = 100.0; // deixar pouco brilhante
            blinn_phong_specular_term = refletancia_difusa*I*pow(max(0,dot(n,h)), q);
            Kd0 = texture(TextureMeteoro, vec2(U,V)).rgb;
            break;
        }

    // Equa��o de Ilumina��o
    float lambert = max(0,dot(n,l));


    cor_vertex = Kd0   * (lambert + 0.5) + blinn_phong_specular_term;
}

