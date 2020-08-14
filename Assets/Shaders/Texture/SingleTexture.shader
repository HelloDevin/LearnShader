Shader "Wdx/ShaderBook/SingleTexture"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex",2D )="white"{ }
        _Specular ("Specular Color ", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment  frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            //纹理名+ST 
            float4 _MainTex_ST;//xy存储缩放值 zw存储偏移值
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord:TEXCOORD0 ; 

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : COLOR0;
                float3 worldPos : TEXCOORD0;
                float2 uv:TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f f;

                f.pos = UnityObjectToClipPos(v.vertex);

                f.worldNormal=UnityObjectToWorldNormal(v.normal);

                f.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;

                f.uv=v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
                //上面等价于
                //f.uv=TRANSFORM_TEX(v.texcoord,_MainTex);

                return f;
            }

            fixed4 frag(v2f f) : SV_Target
            {

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(f.worldNormal);

                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));

                float3 albedo=tex2D(_MainTex,f.uv).rgb*_Color.rgb;

                fixed3 diffuse = _LightColor0.rgb * albedo * (dot(worldNormal, lightDir)*0.5+0.5);

                fixed3 viewDir =normalize(UnityWorldSpaceViewDir(f.worldPos));   

                fixed3 halfDir=normalize(lightDir+viewDir);

                fixed3 specular  =_LightColor0.rgb*_Specular.rgb*pow(saturate(dot(halfDir,worldNormal)),_Gloss);

                fixed3 color = ambient + diffuse+specular;

                return fixed4(color, 1);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}