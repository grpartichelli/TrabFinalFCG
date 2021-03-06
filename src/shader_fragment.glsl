#version 330 core

// Atributos de fragmentos recebidos como entrada ("in") pelo Fragment Shader.
// Neste exemplo, este atributo foi gerado pelo rasterizador como a
// interpolação da posição global e a normal de cada vértice, definidas em
// "shader_vertex.glsl" e "main.cpp".
in vec4 position_world;
in vec4 normal;
in vec3 cor_vertex;

// Posição do vértice atual no sistema de coordenadas local do modelo.
in vec4 position_model;

// Coordenadas de textura obtidas do arquivo OBJ (se existirem!)
in vec2 texcoords;

// Matrizes computadas no código C++ e enviadas para a GPU
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Identificador que define qual objeto está sendo desenhado no momento
#define TROPHY 0
#define FLOOR 1
#define TORRE 2
#define ROBOTTOP 3
#define ROBOTBOTTOM 4
#define METEOR 5
#define PLATFORM 6
uniform int object_id;

// Parâmetros da axis-aligned bounding box (AABB) do modelo
uniform vec4 bbox_min;
uniform vec4 bbox_max;

// Variáveis para acesso das imagens de textura
uniform sampler2D TextureOuro;
uniform sampler2D TextureGrama;
uniform sampler2D TextureTijolo;
uniform sampler2D TextureMetalClaro;
uniform sampler2D TextureMetalEscuro;
uniform sampler2D TextureMeteoro;


// O valor de saída ("out") de um Fragment Shader é a cor final do fragmento.
out vec3 color;

// Constantes
#define M_PI   3.14159265358979323846
#define M_PI_2 1.57079632679489661923

void main()
{
    // Obtemos a posição da câmera utilizando a inversa da matriz que define o
    // sistema de coordenadas da câmera.
    vec4 origin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 camera_position = inverse(view) * origin;

    // O fragmento atual é coberto por um ponto que percente à superfície de um
    // dos objetos virtuais da cena. Este ponto, p, possui uma posição no
    // sistema de coordenadas global (World coordinates). Esta posição é obtida
    // através da interpolação, feita pelo rasterizador, da posição de cada
    // vértice.
    vec4 p = position_world;

    // Normal do fragmento atual, interpolada pelo rasterizador a partir das
    // normais de cada vértice.
    vec4 n = normalize(normal);

    // Vetor que define o sentido da fonte de luz em relação ao ponto atual.
    vec4 l = normalize(vec4(1.0,1.0,0.0,0.0));

    // Vetor que define o sentido da câmera em relação ao ponto atual.
    vec4 v = normalize(camera_position - p);

    // Blinn-Phong Illumination
    vec3 I = vec3(1.0, 1.0, 1.0);
    vec3 refletancia_difusa;
    vec4 h;
    float q;
    vec3 blinn_phong_specular_term;// = vec3(0.0, 0.0, 0.0); //inicializando em 0 para poder calcular somente em alguns objetos
    //BBOX
    float minx = bbox_min.x;
    float maxx = bbox_max.x;

    float miny = bbox_min.y;
    float maxy = bbox_max.y;

    float minz = bbox_min.z;
    float maxz = bbox_max.z;

    // Coordenadas de textura U e V
    float U = (position_model[0] - minx)/(maxx-minx); //Pré calculando uma projeção planar
    float V = (position_model[1] - miny)/(maxy-miny); //Pré calculando uma projeção planar

    //Pré calculando a projeção esférica
    vec4 bbox_center   = (bbox_min + bbox_max) / 2;
    vec4 p_vec = bbox_center + ((position_model - bbox_center)/length(position_model - bbox_center));
    float theta = atan(p_vec[0],p_vec[2]);
    float phi = asin(p_vec[1]);


    vec3 Kd0;
    switch(object_id)
    {
        case FLOOR:
            //PROJEÇÃO DO CHÃO UTILIZANDO UM ESTILO REPEAT
            U = position_model[0];
            U = U -floor(U);
            V = position_model[2];
            V = V - floor(V);
            //Utilizando a textura de grama para o chão
            Kd0 = texture(TextureGrama, vec2(U,V)).rgb;
            refletancia_difusa = vec3(0.5,1.0,0.5); // luz esverdeada
            h = normalize(v + l);
            q = 50.0;
            blinn_phong_specular_term = refletancia_difusa*I*pow(max(0,dot(n,h)), q);
            break;
        // PROJEÇÃO PLANAR PARA A TORRE
        case TORRE:
            Kd0 = texture(TextureTijolo, vec2(U,V)).rgb; //Utilizando a textura de tijolo para a torre

            break;
        case ROBOTBOTTOM:
            Kd0 = texture(TextureMetalEscuro, vec2(U,V)).rgb;  //Utilizando a textura de metal escuro para a parte de baixo

            refletancia_difusa = vec3(0.8,0.8,0.8);
            h = normalize(v + l);
            q = 32.0;
            blinn_phong_specular_term = refletancia_difusa*I*pow(max(0,dot(n,h)), q);

            break;
        //PROJEÇÃO ESFÉRICA PARA A PLATAFORMA
        case PLATFORM:
            U = (theta + M_PI)/(2*M_PI);
            V = (phi + M_PI_2)/M_PI;
            Kd0 = texture(TextureTijolo, vec2(U,V)).rgb;

            refletancia_difusa = vec3(0.8,0.8,0.6); //levemente amarelada
            h = normalize(v + l);
            q = 32.0;
            blinn_phong_specular_term = refletancia_difusa*I*pow(max(0,dot(n,h)), q);

            break;
        }

    // Equação de Iluminação
    float lambert = max(0,dot(n,l));


    // Cor final com correção gamma, considerando monitor sRGB.
    // Veja https://en.wikipedia.org/w/index.php?title=Gamma_correction&oldid=751281772#Windows.2C_Mac.2C_sRGB_and_TV.2Fvideo_standard_gammas
    if(object_id == TROPHY || object_id == METEOR || object_id == ROBOTTOP) { // esses 3 usam gouraud
        color = pow(cor_vertex, vec3(1.0,1.0,1.0)/2.2);
    } else {
        color = Kd0  * (lambert + 0.5);
        if (object_id == FLOOR || object_id == ROBOTBOTTOM || object_id == PLATFORM) {
            color += blinn_phong_specular_term; // esses 3 usam blinn-phong
        }
        color = pow(color, vec3(1.0,1.0,1.0)/2.2); // sobrou a torre que fica soh com lambert
    }
}
