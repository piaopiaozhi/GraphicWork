using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Zoom : MonoBehaviour
{
    // shader
    public Shader myShader;
    //���� 
    public Material mat = null;

    // �Ŵ�ǿ��
    [Range(-2.0f, 2.0f), Tooltip("�Ŵ�ǿ��")]
    public float zoomFactor = 0.4f;

    // �Ŵ󾵴�С
    [Range(0.0f, 0.2f), Tooltip("�Ŵ󾵴�С")]
    public float size = 0.15f;

    // ͹����Եǿ��
    [Range(0.0001f, 0.1f), Tooltip("͹����Եǿ��")]
    public float edgeFactor = 0.05f;

    // ��������λ��
    private Vector2 pos = new Vector4(0.5f, 0.5f);

    void Start()
    {
        //�ҵ���Ӧ��Shader�ļ�  
        myShader = Shader.Find("lcl/screenEffect/Zoom");
    }

    // ��Ⱦ��Ļ
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (mat)
        {
            // ��������괫�ݸ�Shader
            mat.SetVector("_Pos", pos);
            mat.SetFloat("_ZoomFactor", zoomFactor);
            mat.SetFloat("_EdgeFactor", edgeFactor);
            mat.SetFloat("_Size", size);
            // ��Ⱦ
            Graphics.Blit(source, destination, mat);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

    void Update()
    {
        if (Input.GetMouseButton(0))
        {
            Vector2 mousePos = Input.mousePosition;
            //��mousePosת��Ϊ��0��1������
            pos = new Vector2(mousePos.x / Screen.width, mousePos.y / Screen.height);
        }
    }

}
