Shader "Wdx/ShaderToy/TestShader"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 color : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);

				o.color = UnityObjectToWorldNormal(v.normal);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return fixed4(i.color,1.0);
			}
			ENDCG
		}
	}
}